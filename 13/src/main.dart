import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);
  var input = await file.readAsString();
  solvePuzzle1(input);
  solvePuzzle2(input);
}

void solvePuzzle2(String input) {
  List<PacketEntryList> packets = [];
  var pairSplit = input.split("\n");

  for (var i = 1; i < pairSplit.length; i = i + 3) {
    var lineLeft = pairSplit[i - 1];
    var lineRight = pairSplit[i];

    PacketEntryList left = parseList(lineLeft);
    PacketEntryList right = parseList(lineRight);
    packets.add(left);
    packets.add(right);
  }
  print("Parsed ${packets.length} packets");
  packets.add(PacketEntryList.decoder(2));
  packets.add(PacketEntryList.decoder(6));

  packets.sort((left, right) {
    var order = left.compare(right);
    if (order == Order.UNKNOWN) {
      return 0;
    }
    if (order == Order.IN_RIGHT_ORDER) {
      return -1;
    }
    return 1;
  });

  var decoderKey = packets
      .where((element) => element.decoder)
      .map((e) => packets.indexOf(e) + 1)
      .reduce((value, element) => value * element);

  print("decoder key is $decoderKey");
}

void solvePuzzle1(String input) {
  List<Pair> pairs = [];
  var pairSplit = input.split("\n");

  for (var i = 1; i < pairSplit.length; i = i + 3) {
    var lineLeft = pairSplit[i - 1];
    var lineRight = pairSplit[i];
    print("Pair ${pairs.length + 1} \n $lineLeft \n $lineRight \n\n");
    PacketEntryList left = parseList(lineLeft);
    PacketEntryList right = parseList(lineRight);
    pairs.add(new Pair(left, right));
  }
  print("Parsed ${pairs.length} pairs");

  var sum = 0;
  for (var i = 0; i < pairs.length; i++) {
    if (pairs[i].compare() == Order.IN_RIGHT_ORDER) {
      print("Pair ${i + 1} is in right order. ");
      sum += i + 1;
    }
  }

  print("The sum of the indices in right order is $sum");
}

PacketEntryList parseList(String line) {
  PacketEntryList root = PacketEntryList.empty(null);

  PacketEntryList? current = null;
  String digits = "";
  for (var i = 1; i < line.length - 1; i++) {
    if (line[i] == "[") {
      if (current == null) {
        PacketEntryList list = new PacketEntryList.empty(root);
        current = list;
        root.add(list);
      } else {
        PacketEntryList list = new PacketEntryList.empty(current);
        current.add(list);
        current = list;
      }
    } else if (line[i] == "]") {
      int? number = null;
      if (digits.length > 0) {
        number = int.parse(digits);
        digits = "";
      }
      if (current == null) {
        if (number != null) {
          root.add(PacketEntryInteger(number, root));
        }
        continue;
      }
      if (number != null) {
        current.add(PacketEntryInteger(number, current));
      }
      current = current.parent;
    } else if (line[i] == ",") {
      if (digits.length > 0) {
        var number = int.parse(digits);
        digits = "";
        if (current == null) {
          root.add(PacketEntryInteger(number, root));
        } else {
          current.add(PacketEntryInteger(number, current));
        }
      }
      continue;
    }
    if (int.tryParse(line[i]) != null) {
      digits += line[i];
    }
  }
  return root;
}

class Pair {
  final PacketEntryList packetLeft;
  final PacketEntryList packetRight;

  Pair(this.packetLeft, this.packetRight);

  Order compare() {
    return packetLeft.compare(packetRight);
  }
}

abstract class PacketEntry {
  final PacketEntryList? parent;

  PacketEntry(this.parent);
  Order compareToInt(PacketEntryInteger right);
  Order compareToList(PacketEntryList right);

  Order compare(PacketEntry right) {
    if (right is PacketEntryInteger) {
      return this.compareToInt(right);
    }
    if (right is PacketEntryList) {
      return this.compareToList(right);
    }
    throw new Exception("unknown packet entry type");
  }
}

class PacketEntryInteger extends PacketEntry {
  final int value;

  PacketEntryInteger(this.value, PacketEntryList? parent) : super(parent);

  Order compareToInt(PacketEntryInteger right) {
    if (this.value < right.value) {
      return Order.IN_RIGHT_ORDER;
    } else if (this.value == right.value) {
      return Order.UNKNOWN;
    } else {
      return Order.OUT_OF_ORDER;
    }
  }

  Order compareToList(PacketEntryList right) {
    return PacketEntryList.from(this, this.parent).compareToList(right);
  }
}

class PacketEntryList extends PacketEntry {
  final List<PacketEntry> values;
  final bool decoder;

  PacketEntryList(this.values, PacketEntryList? parent)
      : this.decoder = false,
        super(parent);

  PacketEntryList.empty(PacketEntryList? parent)
      : this.values = [],
        this.decoder = false,
        super(parent);

  PacketEntryList.from(PacketEntryInteger entryInteger, PacketEntryList? parent)
      : this.values = [entryInteger],
        this.decoder = false,
        super(parent);

  PacketEntryList.decoder(int value)
      : this.values = [PacketEntryInteger(value, null)],
        decoder = true,
        super(null);

  void add(PacketEntry value) {
    this.values.add(value);
  }

  Order compareToInt(PacketEntryInteger right) {
    return this.compareToList(PacketEntryList.from(right, right.parent));
  }

  Order compareToList(PacketEntryList right) {
    for (var i = 0; i < this.length; i++) {
      if (right.length < i + 1) {
        return Order.OUT_OF_ORDER;
      }
      PacketEntry rightValue = right.getValue(i);
      PacketEntry leftValue = this.getValue(i);
      Order order = leftValue.compare(rightValue);
      if (order != Order.UNKNOWN) {
        return order;
      }
    }

    if (this.length < right.length) {
      return Order.IN_RIGHT_ORDER;
    }
    if (this.length == right.length) {
      return Order.UNKNOWN;
    }

    return Order.UNKNOWN;
  }

  num get length => values.length;

  PacketEntry getValue(int index) {
    return values[index];
  }
}

enum Order { OUT_OF_ORDER, IN_RIGHT_ORDER, UNKNOWN }
