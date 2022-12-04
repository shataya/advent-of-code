import 'dart:io';
import 'package:path/path.dart' as p;

// 1 Rock, 2 Paper, 3 Scissors
final mapping = {'A': 1, 'B': 2, 'C': 3, 'X': 1, 'Y': 2, 'Z': 3};
final text = {1: 'Rock', 2: 'Paper', 3: 'Scissors'};
// 0 is draw, -1 is lost, 6 is win

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);

  var lines = await file.readAsLines();
  var totalScore = 0;
  for (var line in lines) {
    var split = line.split(' ');
    var a = split[0]; //opponent
    var b = split[1]; //me
    int result;
    if (mapping[a] == mapping[b]) {
      result = 3;
    } else if ((mapping[b] == 1 && mapping[a] == 3) ||
        (mapping[b] == 2 && mapping[a] == 1) ||
        (mapping[b] == 3 && mapping[a] == 2)) {
      result = 6;
    } else {
      result = 0;
    }

    int shapeScore = mapping[b] ?? 0;
    print(
        "${text[mapping[a]]} x ${text[mapping[b]]} -> Score: ${result} + ${mapping[b]}");
    totalScore += (result + shapeScore);
  }

  print("Total Score: $totalScore");
}
