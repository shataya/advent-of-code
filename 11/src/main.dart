import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:math_expressions/math_expressions.dart';

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);
  var lines = await file.readAsLines();
  solvePuzzle1(lines);
  solvePuzzle2(lines);
}

void solvePuzzle1(List<String> lines) {
  MonkeyInTheMiddle m = parse(lines);

  int rounds = 20;
  List.generate(rounds, (i) => 1).forEach((element) => m.playRound());

  print("Monkey business is ${m.monkeyBusiness}");
}

void solvePuzzle2(List<String> lines) {
  MonkeyInTheMiddle m = parse(lines);
  m.enableHighWorryMode();

  var divisors = m.monkeys.map((e) => e.test.divisor).toList();
  print("Divisors: $divisors");
  var x = divisors.reduce((value, element) => value * element);
  print("Multiply divisors: $x");

  int rounds = 10000;
  List.generate(rounds, (i) => 1).forEach((element) => m.playRound());

  print("Monkey business is ${m.monkeyBusiness}");
}

MonkeyInTheMiddle parse(List<String> lines) {
  Parser parser = Parser();
  int index = 0;
  Queue<Item>? items = null;
  Operation? operation;
  int? divisor;
  int? indexIfTrue;
  int? indexIfFalse;
  List<Monkey> monkeys = [];
  for (var line in lines) {
    if (line.startsWith("Monkey")) {
      var split = line.replaceAll(":", "").split(" ");
      index = int.parse(split[1]);
    }
    if (line.contains("  Starting items:")) {
      var tmp = line.replaceAll("Starting items: ", "");
      tmp = tmp.replaceAll(" ", "");
      var numbers = tmp.split(",");
      print("parse items, $numbers");
      items =
          Queue.from(numbers.map((e) => new Item(BigInt.parse(e))).toList());
    }
    if (line.contains("Operation: ")) {
      var type;
      if (line.contains("*")) {
        type = OperationType.MULTIPLY;
        if (line.contains("old * old")) {
          type = OperationType.POW;
        }
      } else if (line.contains("+")) {
        type = OperationType.ADD;
      }
      var split = line.split(" ");
      print(split);
      var operand = type == OperationType.POW
          ? null
          : BigInt.parse(split[split.length - 1]);
      operation = new Operation(type, operand);
    }
    if (line.contains("Test: ")) {
      var split = line.split(" ");
      divisor = int.parse(split[split.length - 1]);
    }
    if (line.contains("If true")) {
      var split = line.split(" ");
      indexIfTrue = int.parse(split[split.length - 1]);
    }
    if (line.contains("If false")) {
      var split = line.split(" ");
      indexIfFalse = int.parse(split[split.length - 1]);
    }
    if (line.length == 0) {
      print("Create new monkey with index $index");
      Monkey monkey = new Monkey(index, items!, operation!,
          DivisibleByTest(divisor!, indexIfTrue!, indexIfFalse!));
      monkeys.add(monkey);
    }
  }

  return new MonkeyInTheMiddle(monkeys);
}

class MonkeyInTheMiddle {
  final List<Monkey> monkeys;
  WorryMode worryMode;
  int round;
  BigInt optimizeDivisor;

  MonkeyInTheMiddle(this.monkeys)
      : worryMode = WorryMode.NORMAL,
        this.round = 0,
        optimizeDivisor = BigInt.from(monkeys
            .map((e) => e.test.divisor)
            .reduce((value, element) => value * element));

  void enableHighWorryMode() {
    this.worryMode = WorryMode.HIGH;
  }

  void playRound() {
    round++;
    monkeys.forEach((m) => playTurn(m));
    print("Round $round finished.");
  }

  void playTurn(Monkey monkey) {
    while (monkey.items.isNotEmpty) {
      var item = monkey.items.removeFirst();
      playItem(monkey, item);
    }
  }

  void playItem(Monkey monkey, Item item) {
    monkey.inspect(item, worryMode);
    if (item.worryLevel > optimizeDivisor) {
      var newLevel = (item.worryLevel % optimizeDivisor);

      item.worryLevel = newLevel;
    }

    int targetMonkeyIndex = monkey.test.check(item.worryLevel);
    monkeys[targetMonkeyIndex].catchItem(item);
  }

  int get monkeyBusiness {
    var counters = monkeys.map((e) => e.inspectionCounter).toList();
    counters.sort();
    return counters
        .skip(counters.length - 2)
        .reduce((value, element) => value * element);
  }
}

class DivisibleByTest {
  final int divisor;
  final int indexIfTrue;
  final int indexIfFalse;

  DivisibleByTest(this.divisor, this.indexIfTrue, this.indexIfFalse);

  int check(BigInt value) {
    if (value % BigInt.from(divisor) == BigInt.zero) {
      return indexIfTrue;
    } else {
      return indexIfFalse;
    }
  }
}

class Operation {
  final OperationType type;
  final BigInt? operand;

  Operation(this.type, this.operand);

  BigInt calc(BigInt value) {
    if (type == OperationType.ADD) {
      return value + operand!;
    } else if (type == OperationType.MULTIPLY) {
      return value * operand!;
    } else {
      return value * value;
    }
  }
}

class Item {
  BigInt worryLevel;

  Item(this.worryLevel);

  void apply(Operation worryLevelOperation, WorryMode mode) {
    BigInt newLevel = worryLevelOperation.calc(this.worryLevel);

    if (mode == WorryMode.NORMAL) {
      var div = BigInt.from(3);
      newLevel = BigInt.from((newLevel / div).floor());
    }

    this.worryLevel = newLevel;
  }
}

class Monkey {
  final int index;
  final Queue<Item> items;
  final Operation worryLevelOperation;
  final DivisibleByTest test;
  int inspectionCounter;

  Monkey(this.index, this.items, this.worryLevelOperation, this.test)
      : this.inspectionCounter = 0;

  void inspect(Item item, WorryMode mode) {
    item.apply(worryLevelOperation, mode);
    inspectionCounter++;
  }

  void catchItem(Item item) {
    items.addLast(item);
  }
}

enum WorryMode { NORMAL, HIGH }

enum OperationType { ADD, MULTIPLY, POW }
