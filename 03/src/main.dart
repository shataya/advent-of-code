import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);

  var lines = await file.readAsLines();

  solvePuzzle1(lines);
  solvePuzzle2(lines);
}

void solvePuzzle2(List<String> lines) {
  var total = 0;
  var group = [];
  for (var line in lines) {
    if (group.length < 3) {
      group.add(getItems(line, 0, line.length));
    }

    if (group.length == 3) {
      int duplicate = findDuplicateOfThree(group[0], group[1], group[2]);
      total += duplicate;
      group.clear();
    }
  }
  print("Total (2): $total");
}

void solvePuzzle1(List<String> lines) {
  var total = 0;
  for (var line in lines) {
    int halfLength = (line.length / 2).round();
    var first = getItems(line, 0, halfLength);
    var second = getItems(line, halfLength, halfLength);
    int duplicate = findDuplicate(first, second);
    total += duplicate;
    print("Duplicate: $duplicate");
  }
  print("Total: $total");
}

Iterable<int> getItems(String line, int skip, int length) =>
    line.codeUnits.skip(skip).take(length).map((e) => getPriority(e));

int findDuplicate(Iterable<int> first, Iterable<int> second) =>
    first.firstWhere((element) => second.contains(element));

int findDuplicateOfThree(
        Iterable<int> first, Iterable<int> second, Iterable<int> third) =>
    first.firstWhere(
        (element) => second.contains(element) && third.contains(element));

int getPriority(int c) {
  if (c >= getAsciiValue('A') && c <= getAsciiValue('Z')) {
    return c - 38;
  } else {
    return c - 96;
  }
}

int getAsciiValue(String c) {
  return c.codeUnitAt(0);
}
