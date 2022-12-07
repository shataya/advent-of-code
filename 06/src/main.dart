import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as p;

const startOfPacketMarkerLength = 4;
const startOfMessageMarkerLength = 14;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);

  var input = await file.readAsString();

  solvePuzzle(input, startOfPacketMarkerLength);
  solvePuzzle(input, startOfMessageMarkerLength);
}

void solvePuzzle(String input, int markerLength) {
  Queue<int> marker = new Queue();
  HashSet<int> checkSet = new HashSet();
  int index = 1;

  for (var c in input.runes) {
    if (marker.length == markerLength) {
      marker.removeFirst();
    }
    marker.addLast(c);
    if (marker.length == markerLength) {
      checkSet.addAll(marker);
    }

    if (checkSet.length == markerLength) {
      break;
    }
    checkSet.clear();
    index++;
  }

  print("Marker found at $index");
}
