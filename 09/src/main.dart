import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);

  var lines = await file.readAsLines();

  solvePuzzle(lines);
}

void solvePuzzle(List<String> lines) {
  List<Move> moves = [];
  Position max = new Position(0, 0);
  Position min = new Position(0, 0);
  Position pos = new Position(0, 0);
  for (var line in lines) {
    Move move = parseMove(line);
    if (move.steps > 1) {
      moves.addAll(
          List.generate(move.steps, (index) => new Move(move.direction, 1)));
    } else {
      moves.add(move);
    }

    pos.move(move);
    if (pos.y > max.y) max.y = pos.y;
    if (pos.y < min.y) min.y = pos.y;
    if (pos.x > max.x) max.x = pos.x;
    if (pos.x < min.x) min.x = pos.x;
  }

  Grid grid = new Grid(max.x + min.x.abs() + 1, max.y + min.y.abs() + 1);
  print(
      "${moves.length} total moves. Grid has ${grid.width} width and ${grid.height} height.");

  Position start = new Position(min.x.abs(), min.y.abs());
  print("Max: $max, Min: $min, Normalized Start: $start");

  simulate(start, grid, moves, 2);
  simulate(start, grid, moves, 10);
}

void simulate(Position start, Grid grid, List<Move> moves, int knots) {
  grid.reset();
  RopeSimulation sim = new RopeSimulation(new Rope(start, knots), grid);
  moves.forEach((element) {
    sim.apply(element);
  });
  var visited = sim.grid.cells
      .map((e) => e.map((e) => e.visited ? 1 : 0))
      .expand((element) => element)
      .reduce((value, element) => value + element);
  print("total visited: $visited");
}

Move parseMove(String line) {
  var split = line.split(" ");
  var direction =
      Direction.values.firstWhere((element) => element.name == split[0]);
  var steps = int.parse(split[1]);
  return new Move(direction, steps);
}

class Position {
  int x;
  int y;

  Position(this.x, this.y);
  @override
  String toString() {
    return "[$x,$y]";
  }

  Position.from(Position other)
      : x = other.x,
        y = other.y;

  void move(Move move) {
    if (move.direction == Direction.U) {
      y += move.steps;
    }
    if (move.direction == Direction.D) {
      y -= move.steps;
    }
    if (move.direction == Direction.R) {
      x += move.steps;
    }
    if (move.direction == Direction.L) {
      x -= move.steps;
    }
  }
}

class Rope {
  Position head;
  List<Position> tailParts;

  Rope(Position start, int knots)
      : head = Position.from(start),
        tailParts = List.generate(knots - 1, (index) => Position.from(start));

  void move(Move move) {
    head.move(move);
    var prev = head;
    for (var t in tailParts) {
      updateTail(prev, t);
      prev = t;
    }
  }

  Position updateTail(Position anchor, Position tail) {
    if (anchor.x == tail.x && anchor.y == tail.y) {
      return tail;
    }
    int diffY = (anchor.y - tail.y).abs();
    int diffX = (anchor.x - tail.x).abs();

    if (anchor.x == tail.x && diffY > 1) {
      if (anchor.y > tail.y) {
        tail.y++;
      } else {
        tail.y--;
      }
    } else if (anchor.y == tail.y && diffX > 1) {
      if (anchor.x > tail.x) {
        tail.x++;
      } else {
        tail.x--;
      }
    } else if (anchor.y != tail.y && diffX > 1) {
      if (anchor.y > tail.y) {
        tail.y++;
      } else {
        tail.y--;
      }
      if (anchor.x > tail.x) {
        tail.x++;
      } else {
        tail.x--;
      }
    } else if (anchor.x != tail.x && diffY > 1) {
      if (anchor.x > tail.x) {
        tail.x++;
      } else {
        tail.x--;
      }
      if (anchor.y > tail.y) {
        tail.y++;
      } else {
        tail.y--;
      }
    }
    return tail;
  }
}

class RopeSimulation {
  final Rope rope;
  final Grid grid;

  RopeSimulation(this.rope, this.grid) {
    this.grid.visit(rope.head.x, rope.head.y);
  }

  void apply(Move move) {
    rope.move(move);
    this.grid.visit(rope.tailParts.last.x, rope.tailParts.last.y);
  }
}

class Grid {
  final int width;
  final int height;
  final List<List<Cell>> cells;

  Grid(this.width, this.height)
      : cells = List.generate(
            height, (index) => List.generate(width, (index) => new Cell()));

  void reset() {
    cells.forEach((element) {
      element.forEach((cell) => cell.visited = false);
    });
  }

  void visit(int x, int y) {
    cells[y][x].visited = true;
  }
}

class Cell {
  bool visited;

  Cell() : visited = false;
}

class Move {
  final Direction direction;
  final int steps;

  Move(this.direction, this.steps);

  @override
  String toString() {
    return "$direction $steps";
  }
}

enum Direction { U, R, L, D }
