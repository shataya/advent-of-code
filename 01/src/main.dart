import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);

  var lines = await file.readAsLines();
  List<int> elves = [];
  var currentCal = 0;
  for (var line in lines) {
    if (line.length > 0) {
      var cal = int.parse(line);
      currentCal += cal;
    } else {
      elves.add(currentCal);
      currentCal = 0;
    }
  }
  elves.sort();
  var maxCalories = elves.last;
  var size = elves.length;
  var topThree = elves[size - 1] + elves[size - 2] + elves[size - 3];
  print("Max calories is $maxCalories calories, topThree is $topThree");
}
