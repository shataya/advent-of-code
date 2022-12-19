import 'dart:collection';
import 'dart:io';
import 'package:dart_numerics/dart_numerics.dart';
import 'package:path/path.dart' as p;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);
  var input = await file.readAsLines();
  var valves = parse(input);
  solvePuzzle(valves);
}

int maxNumberOfValvesToOpen = 0;
Map<String, Valve> valvesMap = {};

List<Valve> parse(List<String> input) {
  List<Valve> valves = [];
  for (var line in input) {
    var id = "rate=";
    var i = line.indexOf(id);
    var rate = int.parse(line.substring(i + id.length, line.indexOf(";")));
    var name = line.substring(line.indexOf(" ") + 1, line.indexOf("has") - 1);
    valves.add(new Valve(name, rate));
  }
  var index = 0;
  for (var line in input) {
    var id = "to valve";
    var i = line.indexOf(id);
    var sub = line.substring(i + id.length);
    if (sub.startsWith("s")) {
      sub = sub.substring(1);
    }
    var toValves = sub.trim().split(", ");
    Valve valve = valves[index];
    var to = valves.where((v) => toValves.contains(v.name));
    valve.to.addAll(to);
    index++;
  }

  valves.forEach((v) => print(v));
  return valves;
}

Map<String, Map<int, Map<OpenValves, int>>> results = {};

void solvePuzzle(List<Valve> valves) {
  valves.forEach((v) {
    valvesMap.putIfAbsent(v.name, () => v);
  });
  Valve start = valves.firstWhere((v) => v.name == "AA");
  maxNumberOfValvesToOpen = valves.where((v) => v.rate > 0).length;
  print("Max number of valves to open: $maxNumberOfValvesToOpen");
  Simulation simulation = new Simulation(start);
  int maxReleased = findMaxReleased(simulation);
  print("Max released: $maxReleased");
}

int findMaxReleased(Simulation sim) {
  if (sim.finished) {
    return sim.released;
  } else {
    return max(sim.current.to
        .map((e) => copyAndGoTo(sim, e))
        .where((element) => element != null)
        .map((e) => findMaxReleased(e!))
        .toList());
  }
}

Simulation? copyAndGoTo(Simulation toCopy, Valve to) {
  var sim = Simulation.copy(toCopy).goTo(to);
  if (!results.containsKey(sim.current.name)) {
    results.putIfAbsent(
        sim.current.name,
        () => {
              sim.minutes: {sim.open: sim.released}
            });
    return sim;
  } else {
    var anyBetter = results[sim.current.name]!.entries.any((minutesMap) =>
        minutesMap.key <= sim.minutes &&
        minutesMap.value.entries.any((openMap) =>
            openMap.key.values.containsAll(sim.open.values) &&
            openMap.value >= sim.released));

    if (anyBetter) {
      return null;
    } else {
      results[sim.current.name]!
          .entries
          .where((minutesMap) => minutesMap.key >= sim.minutes)
          .forEach((minutesMap) {
        minutesMap.value.removeWhere((key, value) =>
            sim.open.values.containsAll(key.values) && value < sim.released);
      });

      results.update(sim.current.name, (value) {
        value.putIfAbsent(sim.minutes, () => {});
        value.update(sim.minutes, (openReleaseMap) {
          openReleaseMap.update(sim.open, (value) => sim.released,
              ifAbsent: () => sim.released);

          return openReleaseMap;
        });
        return value;
      });

      return sim;
    }
  }
}

int max(List<int> list) {
  if (list.isEmpty) {
    return -1;
  }
  list.sort();
  return list.last;
}

class Simulation {
  final OpenValves open;
  int released;
  Valve current;
  int minutes;

  bool get finished => minutes == 30;

  Simulation.copy(Simulation other)
      : this.open = other.open.copy(),
        this.released = other.released,
        this.current = other.current,
        this.minutes = other.minutes;

  Simulation(this.current)
      : this.minutes = 0,
        this.released = 0,
        this.open = new OpenValves();

  void _openValve() {
    if (finished) return;
    if (current.rate > 0 && !open.has(current)) {
      _release();
      open.add(current);
      if (open.maxReached) {
        while (!finished) {
          _release();
        }
      }
    }
  }

  void _release() {
    if (finished) return;
    minutes++;
    open.values.forEach((v) {
      released += valvesMap[v]!.rate;
    });
  }

  Simulation goTo(Valve destination) {
    if (finished) return this;
    _release();
    current = destination;
    _openValve();
    return this;
  }
}

class OpenValves {
  final Set<String> values;

  OpenValves() : this.values = new HashSet();

  int get length => values.length;

  bool get maxReached => this.length >= maxNumberOfValvesToOpen;

  @override
  bool operator ==(Object other) =>
      other is OpenValves &&
      this.values.length == other.values.length &&
      this.values.containsAll(other.values);

  @override
  int get hashCode => values.hashCode;

  OpenValves copy() {
    var tmp = new OpenValves();
    tmp.values.addAll(this.values);
    return tmp;
  }

  bool has(Valve valve) {
    return this.values.contains(valve.name);
  }

  void add(Valve valve) {
    this.values.add(valve.name);
  }
}

class Valve {
  final String name;
  final int rate;
  final List<Valve> to;

  Valve(this.name, this.rate) : to = [];

  @override
  String toString() {
    return "Valve $name has flow rate=$rate; tunnels lead to ${to.length} valves ${to.map((e) => e.name).join(", ")}";
  }
}
