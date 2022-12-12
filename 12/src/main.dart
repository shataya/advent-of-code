import 'dart:collection';
import 'dart:io';
import 'package:dart_numerics/dart_numerics.dart';
import 'package:path/path.dart' as p;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);
  var lines = await file.readAsLines();
  solvePuzzle2(lines);
}

void solvePuzzle1(List<String> lines) {
  Grid grid = parse(lines);
  int length = findShortestPathLength(grid, null);

  print("Shortest path is $length");
}

void solvePuzzle2(List<String> lines) {
  Grid grid = parse(lines);

  List<Node> cellsWithLowestHeight = grid.cells
      .expand((element) => element.where((element) => element.height == 0))
      .toList();
  print("${cellsWithLowestHeight.length} starting points");

  int length = findShortestPathLength(grid, cellsWithLowestHeight);
  print("Shortest path from any square with elevation a is $length");
}

int findShortestPathLength(Grid grid, List<Node>? starts) {
  Graph graph = gridToGraph(grid);

  print("Created graph with ${graph.nodes.length} nodes");
  Dijkstra dijkstra = new Dijkstra();
  dijkstra.findShortestPath(graph);

  if (starts != null && starts.isNotEmpty) {
    var list = starts
        .map((element) => element.shortestPath.length)
        .where((element) => element > 0)
        .toList();
    list.sort();
    return list[0];
  } else {
    return graph.source.shortestPath.length;
  }
}

Grid parse(List<String> lines) {
  Grid grid = Grid();
  for (var line in lines) {
    var runes = line.runes.toList();
    grid.addRow(runes);
  }

  return grid;
}

Graph gridToGraph(Grid grid) {
  Node start = grid.start!;
  Graph graph = Graph.empty(start, grid.end!);

  checkNeighbors(grid.end!, graph);

  return graph;
}

void checkNeighbors(Node current, Graph graph) {
  if (graph.nodes.contains(current)) {
    return;
  }
  current.shortestPath.clear();
  current.neighbors.clear();
  current.distance = int64MaxValue;

  graph.addNode(current);
  if (current.height == 0) {
    return;
  }
  checkNeighbor(current, current.top, graph);
  checkNeighbor(current, current.right, graph);
  checkNeighbor(current, current.down, graph);
  checkNeighbor(current, current.left, graph);
}

void checkNeighbor(Node current, Node? other, Graph graph) {
  if (other != null &&
      isReachable(current, other) &&
      other.type != NodeType.END) {
    current.neighbors.putIfAbsent(other, () => 1);
    checkNeighbors(other, graph);
  }
}

bool isReachable(Node current, Node destination) {
  return destination.height >= current.height ||
      (current.height - destination.height == 1);
}

class Dijkstra {
  Graph findShortestPath(Graph graph) {
    Set<Node> permanentNodes = new HashSet<Node>();
    Set<Node> tmpNodes = new HashSet<Node>();

    graph.destination.distance = 0;
    tmpNodes.add(graph.destination);

    while (tmpNodes.isNotEmpty) {
      Node? current = getLowestDistanceNode(tmpNodes);
      if (current == null) {
        tmpNodes.clear();
      } else {
        tmpNodes.remove(current);

        for (var pair in current.neighbors.entries) {
          Node neighbor = pair.key;
          int weight = pair.value;
          if (!permanentNodes.contains(neighbor)) {
            calcMinDistance(neighbor, weight, current);
            tmpNodes.add(neighbor);
          }
        }
        permanentNodes.add(current);
      }
    }
    return graph;
  }

  void calcMinDistance(Node node, int weight, Node source) {
    int sourceDistance = source.distance;
    if (source.distance + weight < node.distance) {
      node.distance = sourceDistance + weight;
      node.shortestPath.clear();
      node.shortestPath.addAll(source.shortestPath);
      node.shortestPath.add(source);
    }
  }

  Node? getLowestDistanceNode(Set<Node> tmpNodes) {
    Node? minDistanceNode;
    int minDistance = int64MaxValue;
    for (var node in tmpNodes) {
      int distance = node.distance;
      if (distance < minDistance) {
        minDistance = distance;
        minDistanceNode = node;
      }
    }
    return minDistanceNode;
  }
}

class Graph {
  final Set<Node> nodes;
  late Node source;
  late Node destination;

  Graph.empty(this.source, this.destination) : nodes = new HashSet();

  void addNode(Node node) {
    this.nodes.add(node);
  }
}

class Node {
  Node? top;
  Node? right;
  Node? down;
  Node? left;
  final int x;
  final int y;
  final int height;
  NodeType type;

  Node(this.x, this.y, this.height, this.type)
      : distance = int64MaxValue,
        shortestPath = [],
        neighbors = {};

  setNeighbors({Node? t, Node? r, Node? d, Node? l}) {
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

  final List<Node> shortestPath;
  int distance;
  final Map<Node, int> neighbors;

  void addNeighbor(Node node, int distance) {
    neighbors.putIfAbsent(node, () => distance);
  }
}

final int offset = "a".runes.first;

class Grid {
  final List<List<Node>> cells;
  Node? start;
  Node? end;
  Grid() : cells = [];

  addRow(List<int> row) {
    var y = cells.length;
    var x = 0;
    List<Node> tmp = [];
    for (int i in row) {
      var type = NodeType.STANDARD;
      var height = i - offset;

      if (i == "S".runes.first) {
        type = NodeType.START;
        height = 0;
      } else if (i == "E".runes.first) {
        type = NodeType.END;
        height = "z".runes.first - offset;
      }
      var cell = new Node(x, y, height, type);
      if (type == NodeType.START) {
        start = cell;
      } else if (type == NodeType.END) {
        end = cell;
      }
      var t = y > 0 ? cells[y - 1][x] : null;
      var l = x > 0 ? tmp[x - 1] : null;
      cell.setNeighbors(t: t, l: l);
      t?.setNeighbors(d: cell);
      l?.setNeighbors(r: cell);
      tmp.add(cell);
      x++;
    }
    cells.add(tmp);
  }

  @override
  String toString() {
    return cells
        .map((e) => e.map((e) => e.height.toString().padLeft(3)).join(""))
        .join("\n");
  }
}

enum NodeType { STANDARD, START, END }
