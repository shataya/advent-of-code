import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);

  var lines = await file.readAsLines();

  solvePuzzle(lines);
}

void solvePuzzle(List<String> lines) {
  ElveDirectory current = new ElveDirectory(null, "/");
  ElveDirectory root = current;
  List<ElveDirectory> all = [root];

  for (var line in lines) {
    if (line.startsWith("\$ cd ..")) {
      current = current.parent ?? current;
    } else if (line.startsWith("\$ cd")) {
      var name = line.split(" ")[2];
      if (name != "/") {
        var dir = current.findDirectoryByName(name);
        if (dir == null) {
          dir = ElveDirectory(current, name);
          all.add(dir);
        }
        current = dir;
      }
    } else if (line.startsWith("dir")) {
      var name = line.split(" ")[1];
      var dir = current.findDirectoryByName(name);
      if (dir == null) {
        var dir = ElveDirectory(current, name);
        current.addDirectory(dir);
        all.add(dir);
      }
    } else if (!line.startsWith("\$")) {
      var split = line.split(" ");
      current.addFile(ElveFile(split[1], int.parse(split[0])));
    }
  }

  print(root.ls(0));

  const maxSize = 100000;
  const totalSpace = 70000000;
  const neededSpaceForUpdate = 30000000;

  var totalSizeWithMaxSize = all
      .where((element) => element.size() <= maxSize)
      .map((e) => e.size())
      .reduce((value, element) => value + element);

  print("total size with max $maxSize: $totalSizeWithMaxSize");

  var usedSpace = root.size();
  var availableSpace = totalSpace - usedSpace;
  var toDelete = neededSpaceForUpdate - availableSpace;
  print(
      "total used space: $usedSpace, total available: $availableSpace, to delete: $toDelete");

  var smallestDirectoryToDelete = root;
  for (ElveDirectory d in all) {
    if (d.size() >= toDelete && d.size() < smallestDirectoryToDelete.size()) {
      smallestDirectoryToDelete = d;
    }
  }
  print(
      "you need to delete ${smallestDirectoryToDelete.name} with a size of ${smallestDirectoryToDelete.size()}");
}

class ElveFile {
  final String name;
  final int size;

  ElveFile(this.name, this.size);
  @override
  String toString() {
    return "$name (file, size=$size)";
  }
}

class ElveDirectory {
  final ElveDirectory? parent;
  final String name;

  final List<ElveDirectory> directories;
  final List<ElveFile> files;

  @override
  String toString() {
    return "$name (dir)";
  }

  int size() {
    if (files.isEmpty && directories.isEmpty) {
      return 0;
    }
    var fileSize = files.isEmpty
        ? 0
        : files.map((e) => e.size).reduce((value, element) => value + element);
    var dirSize = directories.isEmpty
        ? 0
        : directories
            .map((e) => e.size())
            .reduce((value, element) => value + element);
    return fileSize + dirSize;
  }

  String ls(int depth) {
    var prefix = "";
    for (var i = 0; i < depth + 2; i++) {
      prefix += " ";
    }
    String lsDirs =
        directories.map((e) => "$prefix${e.ls(depth + 2)}\n").join("\n");
    String lsFiles = files.map((e) => "$prefix- $e").join("\n");
    return "- $this \n$lsDirs \n$lsFiles";
  }

  ElveDirectory? findDirectoryByName(String name) {
    var matches = directories.where((element) => element.name == name);
    if (matches.isNotEmpty) {
      return matches.first;
    } else {
      return null;
    }
  }

  void addFile(ElveFile file) {
    files.add(file);
  }

  void addDirectory(ElveDirectory directory) {
    directories.add(directory);
  }

  ElveDirectory(this.parent, this.name)
      : directories = [],
        files = [];
}
