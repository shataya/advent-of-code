import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);

  var lines = await file.readAsLines();

  solvePuzzle(lines);
}

void solvePuzzle(List<String> lines) {
  List<String> crateLines = [];
  List<Move> moves = [];
  Crates? crates = null;

  bool cratesInitialized = false;

  for (var line in lines) {
    if (line.length == 0) {
      continue;
    }
    if (line.startsWith("move")) {
      moves.add(parseMove(line));
      if (!cratesInitialized) {
        crates = createCrateStacks(crateLines);
        cratesInitialized = true;
        crateLines.clear;
        print("$crates");
      }
    } else {
      crateLines.add(line);
    }
  }

  var cratesCopy = crates?.copy();

  moves.forEach((element) {
    print("$element");
    crates?.applyMove(element, false);
    print("$crates");
  });

  print("Top [PUZZLE 1]: ${crates?.getTops().join()}");

  print("and now with the CrateMover 9001....");

  moves.forEach((element) {
    print("$element");
    cratesCopy?.applyMove(element, true);
    print("$crates");
  });

  print("Top [PUZZLE 2]: ${cratesCopy?.getTops().join()}");
}

Move parseMove(String line) {
  var temp = line.replaceFirstMapped("move ", (match) => "");
  temp = temp.replaceFirstMapped("from", (match) => "");
  temp = temp.replaceFirstMapped("to", (match) => "");
  temp = temp.replaceAll("  ", " ");
  var split = temp.split(" ");
  return new Move(
      int.parse(split[0]), int.parse(split[1]) - 1, int.parse(split[2]) - 1);
}

const limiter = ["[", "]", " "];
const numberOfCrates = 9;

Crates createCrateStacks(List<String> crateLines) {
  crateLines.removeLast(); // remove indizes
  var reversed = crateLines.reversed;

  var crates = new Crates.With(numberOfCrates);

  for (var line in reversed) {
    int index = 0;
    line.runes.forEach((rune) {
      var c = String.fromCharCode(rune);

      if (limiter.contains(c)) {
      } else {
        crates.add(getCrateStackIndex(index), c);
      }
      index++;
    });
  }
  return crates;
}

int getCrateStackIndex(int index) {
  return ((index) / 4.0).floor();
}

class Move {
  final int count;
  final int from;
  final int to;

  Move(this.count, this.from, this.to);
  @override
  String toString() {
    return "move $count from $from to $to";
  }
}

class Crates {
  late List<CrateStack> stacks;

  Crates(this.stacks);

  Crates.With(int number) {
    List<CrateStack> temp = [];
    for (var i = 0; i < number; i++) {
      temp.add(new CrateStack());
    }
    this.stacks = temp;
  }

  add(int index, String c) {
    stacks[index].addSingle(c);
  }

  applyMove(Move move, bool sameOrder) {
    stacks[move.to].add(stacks[move.from].remove(move.count, sameOrder));
  }

  @override
  String toString() {
    return stacks
        .map((e) => "[${stacks.indexOf(e)}] " + e.toString())
        .join("\n");
  }

  List<String> getTops() {
    return stacks.map((e) => e.top()).toList();
  }

  Crates copy() {
    return new Crates(this.stacks.map((e) => e.copy()).toList());
  }
}

class CrateStack {
  final Queue<String> crates;

  CrateStack.With(this.crates);
  CrateStack() : this.crates = new Queue<String>();

  void addSingle(String toAdd) {
    crates.addLast(toAdd);
  }

  void add(Queue<String> toAdd) {
    while (toAdd.isNotEmpty) {
      crates.addLast(toAdd.removeFirst());
    }
  }

  Queue<String> remove(int number, bool sameOrder) {
    Queue<String> temp = new Queue();
    for (int i = 0; i < number; i++) {
      if (sameOrder) {
        temp.addFirst(crates.removeLast());
      } else {
        temp.add(crates.removeLast());
      }
    }
    return temp;
  }

  @override
  String toString() {
    return crates.toString();
  }

  String top() {
    return crates.last;
  }

  CrateStack copy() {
    return new CrateStack.With(Queue.from(crates));
  }
}
