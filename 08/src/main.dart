import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:math';

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);

  var lines = await file.readAsLines();

  solvePuzzle(lines);
}

void solvePuzzle(List<String> lines) {
  TreeGrid treeGrid = new TreeGrid(lines[0].length, lines.length);

  for (var line in lines) {
    var row = line.runes.map((e) => runeToInt(e)).toList();
    treeGrid.addTreeRow(row);
  }

  print(treeGrid);
  var visibleTreeCount = treeGrid.getVisibleTreesCount();
  print("$visibleTreeCount are visible.");

  int maxScenicScore = treeGrid.trees
      .map((e) => e.map((e) => e.getScenicScore()))
      .expand((element) => element)
      .reduce(max);

  print("Max possible scenic score is $maxScenicScore.");
}

int runeToInt(int e) => int.parse(String.fromCharCode(e));

class TreeGrid {
  final List<List<Tree>> trees;
  final int width;
  final int height;

  TreeGrid(this.width, this.height) : trees = [];

  addTreeRow(List<int> row) {
    var y = trees.length;
    var x = 0;
    List<Tree> tmp = [];
    for (int i in row) {
      var tree = new Tree(x, y, i);
      var t = y > 0 ? trees[y - 1][x] : null;
      var l = x > 0 ? tmp[x - 1] : null;
      tree.setNeighbors(t: t, l: l);
      t?.setNeighbors(d: tree);
      l?.setNeighbors(r: tree);
      tmp.add(tree);
      x++;
    }
    trees.add(tmp);
  }

  int getVisibleTreesCount() {
    var count = trees
        .map((e) => e.map((e) => e.isVisibleFromOutside() ? 1 : 0))
        .expand((element) => element)
        .reduce((value, element) => value + element);
    return count;
  }
}

class Tree {
  Tree? top;
  Tree? right;
  Tree? down;
  Tree? left;
  final int x;
  final int y;
  final int height;

  Tree(this.x, this.y, this.height);

  setNeighbors({Tree? t, Tree? r, Tree? d, Tree? l}) {
    if (t != null) {
      top = t;
    }
    if (r != null) {
      right = r;
    }
    if (d != null) {
      down = d;
    }
    if (l != null) {
      left = l;
    }
  }

  bool isShorterThan(Tree other) {
    return this.height < other.height;
  }

  bool isVisibleFromOutside() {
    if (top == null || right == null || left == null || down == null) {
      return true;
    } else {
      bool visible = isVisibleInDirection(this, (t) => t.left);
      if (!visible) {
        visible = isVisibleInDirection(this, (t) => t.top);
        if (!visible) {
          visible = isVisibleInDirection(this, (t) => t.right);
          if (!visible) {
            visible = isVisibleInDirection(this, (t) => t.down);
          }
        }
      }

      return visible;
    }
  }

  int getScenicScore() {
    int t = getViewingDistance(this, (t) => t.top);
    int r = getViewingDistance(this, (t) => t.right);
    int d = getViewingDistance(this, (t) => t.down);
    int l = getViewingDistance(this, (t) => t.left);
    return t * r * d * l;
  }

  static int getViewingDistance(Tree start, Tree? getNext(Tree t)) {
    Tree? e = getNext(start);
    int distance = 0;
    while (e != null) {
      distance++;
      if (!e.isShorterThan(start)) {
        break;
      }
      e = getNext(e);
    }
    return distance;
  }

  static bool isVisibleInDirection(Tree start, Tree? getNext(Tree t)) {
    Tree? e = getNext(start);
    var visible = true;
    while (e != null) {
      if (!e.isShorterThan(start)) {
        visible = false;
        break;
      }
      e = getNext(e);
    }
    return visible;
  }
}
