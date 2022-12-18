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

void solvePuzzle(List<Valve> valves) {
  List<Simulation> sims = [];
  Valve start = valves.firstWhere((element) => element.name == "AA");
  int maxReleased = 0;
  int number = 0;
  sims.add(new Simulation(start, number));

  List<Simulation> toAdd = [];
  List<Simulation> toDelete = [];
  while (sims.any((s) => s.minutes < 30)) {
    toAdd.clear();
    toDelete.clear();

    print("${sims.length} simulations are running...");
    var index = 0;
    for (Simulation sim in sims) {
      index++;
      if (index == 0 || index % 1000 == 0) {
        print("sim $index ...");
      }
      if (sim.finished) {
        if (sim.released > maxReleased) {
          maxReleased = sim.released;
        }
        toDelete.add(sim);
        continue;
      }
      var couldBeOpened = sim.isCurrentNotOpenAndFlowRateGreaterThanZero();

      if (couldBeOpened) {
        number++;
        var copy = sim.copy(number);
        copy.simulate(true, null);
        if (checkIfBetter(toAdd, copy) && checkIfBetter(sims, copy)) {
          //print("$copy is better (copy 1)");
          toAdd.add(copy);
        }
      }

      if (sim.current.to.length > 1) {
        for (var to in sim.current.to.skip(1)) {
          number++;
          var copy = sim.copy(number);
          copy.simulate(false, to);
          if (checkIfBetter(toAdd, copy) && checkIfBetter(sims, copy)) {
            //print("$copy is better (copy 2)");
            toAdd.add(copy);
          }
        }
      }
      sim.simulate(false, sim.current.to[0]);
      if (!checkIfBetter(toAdd, sim) || !checkIfBetter(sims, sim)) {
        toDelete.add(sim);
      } else {
        //print("$sim is better (default)");
      }
    }
    sims.addAll(toAdd);
    toDelete.forEach((element) {
      sims.remove(element);
    });
  }

  for (var sim in sims) {
    if (sim.released > maxReleased) {
      maxReleased = sim.released;
    }
  }
  print("Most pressure released: $maxReleased");
}

bool checkIfBetter(List<Simulation> sims, Simulation copy) {
  bool isOtherBetter = sims.any((other) =>
      other != copy &&
      other.current == copy.current &&
      other.released >= copy.released &&
      other.minutes <= copy.minutes &&
      other.open.containsAll(copy.open));
  return !isOtherBetter;
}

class Simulation {
  final int number;
  int minutes = 0;
  final Set<Valve> open;
  int released = 0;
  Valve current;
  Valve? next;

  Simulation(this.current, this.number) : this.open = new HashSet();

  bool get finished => minutes == 30;

  @override
  String toString() {
    return "[$number] Current: ${current.name}, Released: $released, Minutes: $minutes, Opened: ${open.map((e) => e.name).join(", ")}";
  }

  Simulation copy(int number) {
    var copy = new Simulation(this.current, number);
    copy.released = this.released;
    copy.minutes = this.minutes;
    copy.open.addAll(this.open);
    return copy;
  }

  bool isCurrentNotOpenAndFlowRateGreaterThanZero() {
    return this.current.rate > 0 && !this.open.contains(current);
  }

  void simulate(bool openValve, Valve? next) {
    if (minutes == 30) {
      return;
    }
    minutes++;
    var old = released;
    open.forEach((v) {
      released += v.rate;
    });
    //print(
    //  "Current [${current.name}], Opened: ${open.map((e) => e.name).join(", ")}, releasing ${released - old} pressure (all: $released)");
    if (openValve) {
      open.add(current);
      if (next != null) {
        next = next;
        simulate(false, next);
      }
    } else if (next != null) {
      current = next;
    }
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
