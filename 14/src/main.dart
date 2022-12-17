import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);
  var input = await file.readAsLines();
  solvePuzzle2(input);
}

void solvePuzzle1(List<String> input) {
  Cave cave = parseCave(input);
  cave.addCell(500, 0, Type.START);
  print(cave);
  CaveSimulation sim = CaveSimulation.from(cave);
  sim.simulate(false);
  print(cave);
  print("Produced ${sim.unitsOfSand - 1} units of sand");
}

void solvePuzzle2(List<String> input) {
  Cave cave = parseCave(input);
  cave.addCell(500, 0, Type.START);
  cave.addFloor();
  print(cave);
  CaveSimulation sim = CaveSimulation.from(cave);
  sim.simulate(true);
  print(cave);
  print("Produced ${sim.unitsOfSand} units of sand");
}

Cave parseCave(List<String> input) {
  Cave cave = new Cave();
  for (var line in input) {
    var split = line.split(" -> ");
    var x1 = null;
    var y1 = null;
    for (var stroke in split) {
      var coords = stroke.split(",");
      var x = int.parse(coords[0]);
      var y = int.parse(coords[1]);

      if (x1 == null) {
        x1 = x;
        y1 = y;
        continue;
      }

      cave.addLine(x1, y1, x, y);
      x1 = x;
      y1 = y;
    }
  }
  return cave;
}

class CaveSimulation {
  final Cave cave;
  int unitsOfSand;
  int time;

  CaveSimulation.from(this.cave)
      : unitsOfSand = 0,
        time = 0;

  void simulate(bool withFloor) {
    bool end = false;
    while (!end) {
      unitsOfSand++;
      var result = cave.produceSand(withFloor);
      //print(cave);
      time += result!.time;
      if (result.inAbyssFlowing && !withFloor) {
        end = true;
      }
      if (result.full && withFloor) {
        end = true;
      }
    }
  }
}

class Cave {
  final List<List<Type>> cells;
  int width = 0;
  int height = 0;
  int? minNonAirX;
  int? startX;
  int? startY;
  int maxRockY = 0;

  Cave() : this.cells = [];

  void addFloor() {
    var floorY = maxRockY + 2;
    addCell(startX!, floorY, Type.ROCK);
  }

  void addCell(int x, int y, Type type, {bool resize = true}) {
    if (type == Type.START) {
      if (startX != null) {
        throw new Exception("start is already initialized");
      }
      startX = x;
      startY = y;
    }
    if (type == Type.ROCK && y > maxRockY) {
      maxRockY = y;
    }
    if (resize) updateSize(x, y);
    var row = cells[y];
    while (row.length < width) {
      row.add(Type.AIR);
    }
    cells[y][x] = type;
    if (type != Type.AIR && (minNonAirX == null || x < minNonAirX!)) {
      minNonAirX = x;
    }
  }

  void updateSize(int newX, int newY) {
    if (width < (newX + 1)) {
      width = newX + 1;
    }
    if (height < (newY + 1)) {
      height = newY + 1;
    }
    while (cells.length < height) {
      List<Type> row = [];
      cells.add(row);
    }
    for (var y = 0; y < height; y++) {
      if (y >= cells.length) {
        cells.add([]);
      }
      for (var x = 0; x < width; x++) {
        if (x >= cells[y].length) {
          addCell(x, y, Type.AIR, resize: false);
        }
      }
    }
  }

  void addLine(int x1, int y1, int x2, int y2) {
    addCell(x1, y1, Type.ROCK);
    addCell(x2, y2, Type.ROCK);

    if (x1 == x2) {
      var startY = y1 < y2 ? y1 : y2;
      var endY = y1 > y2 ? y1 : y2;
      for (var i = startY; i < endY; i++) {
        addCell(x1, i, Type.ROCK);
      }
      //straight vertical

    } else if (y1 == y2) {
      //straight horizontal
      var startX = x1 < x2 ? x1 : x2;
      var endX = x1 > x2 ? x1 : x2;
      for (var i = startX; i < endX; i++) {
        addCell(i, y1, Type.ROCK);
      }
    }
  }

  @override
  String toString() {
    return cells
        .map((e) => e.skip(minNonAirX ?? 0).map((e) => getIcon(e)).join(""))
        .join("\n");
  }

  getIcon(Type e) {
    switch (e) {
      case Type.AIR:
        return ".";
      case Type.ROCK:
        return "#";
      case Type.SAND:
        return "o";
      case Type.START:
        return "+";
    }
  }

  SimulationStep? produceSand(bool withFloor) {
    if (startX == null || startY == null) {
      return null;
    }

    var time = 1;
    int x = startX!;
    int y = startY!;
    bool rest = false;
    bool inAbyssFlowing = false;
    bool full = false;
    while (!rest) {
      if (!withFloor && y >= maxRockY) {
        rest = true;
        inAbyssFlowing = true;
        break;
      }

      if (withFloor && y == maxRockY - 1) {
        rest = true;
        addCell(x, y, Type.SAND);
        break;
      }

      if (cells[y + 1][x] == Type.AIR) {
        x = x;
        y = y + 1;
        time++;
        continue;
      }
      if ((x - 1) >= 0 && cells[y + 1][x - 1] == Type.AIR) {
        x = x - 1;
        y = y + 1;
        time++;
        continue;
      }

      if (width <= x + 1) {
        updateSize(x + 1, y + 1);
      }
      if (cells[y + 1][x + 1] == Type.AIR) {
        x = x + 1;
        y = y + 1;
        time++;
        continue;
      }
      addCell(x, y, Type.SAND);
      rest = true;
      if (x == startX && y == startY) {
        full = true;
        break;
      }
    }
    return new SimulationStep(time, inAbyssFlowing, full);
  }
}

class SimulationStep {
  final int time;
  final bool inAbyssFlowing;
  final bool full;

  SimulationStep(this.time, this.inAbyssFlowing, this.full);
}

enum Type { AIR, ROCK, SAND, START }
