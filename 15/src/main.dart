import 'dart:collection';
import 'dart:io';
import 'package:dart_numerics/dart_numerics.dart';
import 'package:path/path.dart' as p;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);
  var input = await file.readAsLines();
  List<Sensor> sensors = parseSensors(input);
  solvePuzzle1(sensors);
  solvePuzzle2(sensors);
}

void solvePuzzle2(List<Sensor> sensors) {
  int minY = 0;
  int maxY = 4000000;
  Range maxRange = new Range(minY, maxY);

  List<List<Range>> ranges = [];
  for (var i = minY; i <= maxY; i++) {
    var knownRanges = findKnownRangesInRow(sensors, i);
    if (knownRanges.length > 1) {
      print("more than 1 range");
    }
    knownRanges.removeWhere((element) => !element.overlaps(maxRange));
    var invert = invertRanges(knownRanges, maxRange);
    ranges.add(invert);
  }
  print(
      "${ranges.map((e) => e.length).reduce((value, element) => value + element)} found");
  ranges.where((element) => element.length > 0).forEach((row) {
    row.forEach((element) {
      var y = ranges.indexOf(row);
      var tuningFreq = calcTuningFrequency(element.lower, y);
      print(
          "Possible position for the distress beacon found: x: $element, y: $y, tuning frequency: $tuningFreq");
    });
  });
}

List<Range> invertRanges(List<Range> ranges, Range boundaries) {
  List<Range> invert = [];
  if (ranges.length == 0) {
    // should not be possible
    print("no ranges in row found");
    invert.add(new Range(boundaries.lower, boundaries.upper));
  }
  var minMax = getMinMax(ranges);
  if (boundaries.lower < minMax.lower) {
    invert.add(new Range(boundaries.lower, minMax.lower - 1));
  }
  if (boundaries.upper > minMax.upper) {
    invert.add(new Range(minMax.upper + 1, boundaries.upper));
  }
  if (ranges.length > 1) {
    if (ranges[0].upper < ranges[1].lower) {
      invert.add(new Range(ranges[0].upper + 1, ranges[1].lower - 1));
    }
    if (ranges[1].upper < ranges[0].lower) {
      invert.add(new Range(ranges[1].upper + 1, ranges[0].lower - 1));
    }
    // there should be no more than two ranges
  }
  return invert;
}

Range getMinMax(List<Range> ranges) {
  var max = int64MinValue;
  var min = int64MaxValue;
  for (var range in ranges) {
    if (range.upper >= max) {
      max = range.upper;
    }
    if (range.lower <= min) {
      min = range.lower;
    }
  }
  return new Range(min, max);
}

int calcTuningFrequency(int x, int y) {
  return x * 4000000 + y;
}

//n must have x and y coordinates each no lower than 0 and no larger than 4000000.

void solvePuzzle1(List<Sensor> sensors) {
  var row = 2000000;
  List<Range> xRanges = findKnownRangesInRow(sensors, row);

  print("${xRanges.length} sensor ranges found");
  xRanges.forEach((element) {
    print(element);
  });

  var sumLength =
      xRanges.map((e) => e.length).reduce((value, element) => value + element);
  print("Sum is $sumLength");
}

List<Range> findKnownRangesInRow(List<Sensor> sensors, int row) {
  List<Range> xRanges = [];
  for (var sensor in sensors) {
    if (inRange(sensor.minY, sensor.maxY, row)) {
      var diff = (sensor.value.y - row).abs();
      var xDiff = sensor.distance - diff;
      var range = new Range(sensor.value.x - xDiff, sensor.value.x + xDiff);
      if (!xRanges.any((element) => element.contains(range))) {
        xRanges.removeWhere((element) => range.contains(element));

        var overlaps = checkOverlaps(xRanges, range);

        if (overlaps == null) {
          xRanges
              .add(new Range(sensor.value.x - xDiff, sensor.value.x + xDiff));
        } else {
          while (overlaps != null) {
            overlaps = checkOverlaps(xRanges, overlaps);
          }
        }
      }
    }
  }
  return xRanges;
}

List<Sensor> parseSensors(List<String> input) {
  List<Sensor> sensors = [];
  for (var line in input) {
    var tmp = line
        .replaceAll("Sensor at x=", "")
        .replaceAll(" y=", "")
        .replaceAll(": closest beacon is at x=", ",");
    var split = tmp.split(",");
    Sensor sensor =
        new Sensor(new Point2D(int.parse(split[0]), int.parse(split[1])));
    Beacon beacon =
        new Beacon(new Point2D(int.parse(split[2]), int.parse(split[3])));
    sensor.nearestBeacon = beacon;
    sensors.add(sensor);
  }
  return sensors;
}

Range? checkOverlaps(List<Range> ranges, Range range) {
  var overlap = ranges.firstWhere(
      (element) => element != range && element.overlaps(range),
      orElse: () => range);
  if (overlap != range) {
    overlap.resize(range);
    ranges.removeWhere(
        (element) => overlap != element && overlap.contains(element));
    return overlap;
  } else {
    return null;
  }
}

class Range {
  int lower;
  int upper;

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

  int get length => (upper - lower).abs();

  void resize(Range range) {
    if (range.lower < lower) {
      lower = range.lower;
    }
    if (range.upper > upper) {
      upper = range.upper;
    }
  }
}

bool inRange(int min, int max, int value) {
  return value >= min && value <= max;
}

class Sensor {
  final Point2D value;
  late Beacon nearestBeacon;

  Sensor(this.value);

  int get distance => value.manhattanDistance(nearestBeacon.value);
  int get maxY => value.y + distance;
  int get minY => value.y - distance;
}

class Beacon {
  final Point2D value;

  Beacon(this.value);
}

class Point2D {
  final int x;
  final int y;

  Point2D(this.x, this.y);

  int manhattanDistance(Point2D other) {
    return (x - other.x).abs() + (y - other.y).abs();
  }

  @override
  String toString() {
    return "[$x,$y]";
  }
}
