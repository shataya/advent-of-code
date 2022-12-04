import 'dart:io';
import 'package:path/path.dart' as p;

// 1 Rock, 2 Paper, 3 Scissors

final mapping = {'A': 1, 'B': 2, 'C': 3};
final prediction = {'X': -1, 'Y': 0, 'Z': 1};
final text = {1: 'Rock', 2: 'Paper', 3: 'Scissors'};
// 0 is draw, -1 is lost, 6 is win
final scoring = {0: 3, -1: 0, 1: 6};
void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);

  var lines = await file.readAsLines();
  var totalScore = 0;
  for (var line in lines) {
    var split = line.split(' ');
    var a = split[0];
    var b = split[1];
    var target = prediction[b];

    var predict;
    if (target == 0) {
      predict = mapping[a];
    } else if (target == 1) {
      if (mapping[a] == 3) {
        predict = 1;
      }
      if (mapping[a] == 2) {
        predict = 3;
      }
      if (mapping[a] == 1) {
        predict = 2;
      }
    } else {
      if (mapping[a] == 3) {
        predict = 2;
      }
      if (mapping[a] == 2) {
        predict = 1;
      }
      if (mapping[a] == 1) {
        predict = 3;
      }
    }

    int score = scoring[target] ?? 0;
    int shapeScore = predict;

    totalScore += (score + shapeScore);
  }

  print("Total Score: $totalScore");
}
