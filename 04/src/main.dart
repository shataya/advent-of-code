import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);

  var lines = await file.readAsLines();

  solvePuzzle(lines);
}

void solvePuzzle(List<String> lines) {
  var total = 0;
  var totalOverlaps = 0;

  for (var line in lines) {
    var pair = parsePair(line);

    if (pair.containsFully()) {
      print("$pair : FULLY CONTAINS!");
      total++;
    } else {
      print("$pair : NOT CONTAINS!");
    }

    if (pair.overlaps()) {
      print("$pair : OVERLAPS!");
      totalOverlaps++;
    } else {
      print("$pair : NOT OVERLAPS!");
    }
  }
  print("Total: $total, Total overlaps: $totalOverlaps");
}

Pair parsePair(String line) {
  var split = line.split(',');
  return new Pair(parseRange(split[0]), parseRange(split[1]));
}

Range parseRange(String part) {
  var split = part.split('-');
  return new Range(int.parse(split[0]), int.parse(split[1]));
}

class Range {
  final int lower;
  final int upper;

  Range(this.lower, this.upper);

  bool contains(Range other) {
    return (lower <= other.lower && upper >= other.upper);
  }

  bool overlaps(Range other) {
    return (other.lower >= lower && other.lower <= upper) ||
        (other.upper >= lower && other.upper <= upper);
  }

  String toString() {
    return "$lower-$upper";
  }
}

class Pair {
  final Range a;
  final Range b;

  Pair(this.a, this.b);

  bool containsFully() {
    return a.contains(b) || b.contains(a);
  }

  bool overlaps() {
    return a.overlaps(b) || b.overlaps(a);
  }

  String toString() {
    return "$a,$b";
  }
}
