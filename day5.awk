BEGIN {
  FS = ",";
  pc = 0;
}

function get(addr) {
  return $(1 + addr);
}

function set(addr, val) {
  $(1 + addr) = val;
}

function input() {
  getline inputline < "day5input.txt";
  printf "INPUT: %d\n", inputline;
  return int(inputline);
}

function output(val) {
  printf "OUTPUT: %d\n", val;
}

function ea(addr, pmodes, idx) {
  addr = addr + 1 + idx;
  if (pmodes[idx] == 0) { # position mode
    addr = get(addr);
  }
  # printf "idx=%d, mode=%d, ea=%d\n", idx, pmodes[idx], addr >> "/dev/stderr";
  return addr;
}

function getp(pc, pmodes, idx) {
  return get(ea(pc, pmodes, idx));
}

function setp(pc, pmodes, idx, val) {
  set(ea(pc, modes, idx), val);
}

{
  while(1) {
    instr = int(get(pc));
    opcode = instr % 100;
    pmode = int(instr / 100);
    delete pmodes;
    for(p=0; pmode>0; p++) {
      pmodes[p] = pmode % 10;
      pmode = int(pmode / 10);
    }
    # printf "pc=%d instr=%d opcode=%d pmodes=%d,%d,%d\n", pc, instr, opcode, pmodes[0], pmodes[1], pmodes[2] >> "/dev/stderr";
    if(opcode == 99) {
      break;
    } else if (opcode == 1) {
      setp(pc, pmodes, 2, getp(pc, pmodes, 0) + getp(pc, pmodes, 1));
      pc += 4;
    } else if (opcode == 2) {
      setp(pc, pmodes, 2, getp(pc, pmodes, 0) * getp(pc, pmodes, 1));
      pc += 4;
    } else if (opcode == 3) {
      setp(pc, pmodes, 0, input());
      pc += 2;
    } else if (opcode == 4) {
      output(getp(pc, pmodes, 0));
      pc += 2;
    } else {
      printf "FAIL at pc=%d, opcode=%d\n%s\n", pc, opcode, $0 >> "/dev/stderr"
      exit 1;
    }
  }
}
