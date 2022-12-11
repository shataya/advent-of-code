import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:math' as math;

void main() async {
  var filePath = p.join(Directory.current.path, 'input', 'input.txt');
  File file = File(filePath);

  var lines = await file.readAsLines();

  solvePuzzle(lines);
}

final List<int> cycles = [20, 60, 100, 140, 180, 220];

void solvePuzzle(List<String> lines) {
  Sprite sprite = new Sprite(3);
  CRT crt = new CRT(sprite, 40, 6);
  CPU cpu = new CPU(crt);
  Program program = new Program();
  for (var line in lines) {
    Instruction instruction = parseInstruction(line);
    program.add(instruction);
  }
  print("Read ${program.instructions.length} instructions.");
  cpu.run(program);

  int signalStrengthSum = 0;

  while (!cpu.finished) {
    if (cycles.contains(cpu.cycle)) {
      signalStrengthSum += cpu.signalStrength;
    }
    cpu.process();
  }

  print("The sum of signal strengths is $signalStrengthSum");
}

Instruction parseInstruction(String line) {
  var split = line.split(" ");
  var type =
      InstructionType.values.firstWhere((element) => element.name == split[0]);
  if (type == InstructionType.addx) {
    var value = int.parse(split[1]);
    return Instruction.addx(value);
  } else {
    return Instruction.noop();
  }
}

class Register {
  int value;

  Register.start() : this.value = 1;

  void apply(Instruction instruction) {
    if (instruction.type == InstructionType.noop) {
      return;
    }
    if (instruction.type == InstructionType.addx) {
      value += instruction.value;
    }
  }
}

class Instruction {
  final InstructionType type;
  final int value;
  final int cycles;

  Instruction.noop()
      : this.type = InstructionType.noop,
        this.value = 0,
        this.cycles = 1;

  Instruction.addx(this.value)
      : this.type = InstructionType.addx,
        this.cycles = 2;
}

enum InstructionType { noop, addx }

class InstructionExecution {
  int remainingCycles;
  final Instruction instruction;

  InstructionExecution(this.instruction)
      : this.remainingCycles = instruction.cycles;

  bool process() {
    if (remainingCycles > 0) {
      remainingCycles--;
    }

    return remainingCycles == 0;
  }
}

class Program {
  final Queue<Instruction> instructions;

  Program() : this.instructions = new Queue();

  void add(Instruction instruction) {
    this.instructions.add(instruction);
  }

  Instruction? next() {
    if (instructions.isEmpty) {
      return null;
    }
    return instructions.removeFirst();
  }

  bool get empty {
    return instructions.isEmpty;
  }
}

class Sprite {
  final int width;

  Sprite(this.width);
}

class CRT {
  final Sprite sprite;
  int position;
  final int width;
  final int height;

  CRT(this.sprite, this.width, this.height) : this.position = 0;

  void draw(int spritePosition) {
    if (position >= width) {
      position = 0;
      stdout.write("\n");
    }
    if ((spritePosition - position).abs() <= (sprite.width / 2).floor()) {
      stdout.write("#");
    } else {
      stdout.write(".");
    }
    position++;
  }
}

class CPU {
  final Register register;
  int cycle;
  InstructionExecution? execution;
  Program? program;
  CRT crt;

  CPU(this.crt)
      : this.register = Register.start(),
        this.cycle = 1;

  void add(Instruction instruction) {
    this.execution = new InstructionExecution(instruction);
  }

  int get signalStrength {
    return cycle * register.value;
  }

  void run(Program program) {
    this.program = program;
  }

  get finished {
    return execution == null && (program?.empty ?? true);
  }

  void process() {
    if (execution == null && program == null) {
      return;
    }
    crt.draw(register.value);
    if (execution == null) {
      var next = program!.next();
      if (next != null) {
        execution = new InstructionExecution(next);
      } else {
        return;
      }
    }
    var finished = execution!.process();
    if (finished) {
      register.apply(execution!.instruction);
      execution = null;
    }
    cycle++;
  }
}
