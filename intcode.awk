#! /usr/bin/awk -f

function get(addr, quiet) {
  if(debug >= 2 && !quiet)
    printf "GET: [%d]: %d\n", addr, $(1 + addr) >> "/dev/stderr";
  return int($(1 + addr));
}

function set(addr, val) {
  if(debug >= 2)
    printf "SET: [%d]: %d -> %d\n", addr, $(1 + addr), val >> "/dev/stderr";
  $(1 + addr) = val;
}

function incbase(val) {
  relbase += val;
}

function input() {
  if((getline inputline) > 0) {
    if(debug)
      printf "INPUT: %d\n", inputline >> "/dev/stderr";
    return int(inputline);
  } else {
    printf "INPUT: ERROR" >> "/dev/stderr";
    exit 1;
  }
}

function output(val) {
  if(debug)
    printf "OUTPUT: %d\n", val >> "/dev/stderr";
  print val;
}

function ea(addr, pmodes, idx) {
  addr = addr + 1 + idx;
  if (pmodes[idx] == 0) { # position mode
    addr = get(addr);
  } else if (pmodes[idx] == 2) { # relative mode
    addr = get(addr) + relbase;
  }
  # printf "idx=%d, mode=%d, ea=%d\n", idx, pmodes[idx], addr >> "/dev/stderr";
  return addr;
}

function getp(idx) {
  return get(ea(pc, pmodes, idx));
}

function setp(idx, val) {
  set(ea(pc, pmodes, idx), val); # should not support immediate writes but whatever
}

BEGIN {
  FS = ",";
  OFS = ",";
  pc = 0;
  if(!CODE) CODE=ENVIRON["CODE"];
  getline < CODE;
  while(1) {
    if(debug>2) print $0 >> "/dev/stderr";
    instr = get(pc);
    opcode = instr % 100;
    pmode = int(instr / 100);
    delete pmodes;
    for(p=0; pmode>0; p++) {
      pmodes[p] = pmode % 10;
      pmode = int(pmode / 10);
    }
    if(debug > 0) {
      printf "pc=%d relbase=%d instr=%d opcode=%d pmodes=%d,%d,%d params=%d,%d,%d\n", pc, relbase, instr, opcode, pmodes[0], pmodes[1], pmodes[2], get(pc+1,1), get(pc+2,1), get(pc+3,1) >> "/dev/stderr";
    }
    if(opcode == 99) {
      break;
    } else if (opcode == 1) {
      setp(2, getp(0) + getp(1));
      pc += 4;
    } else if (opcode == 2) {
      setp(2, getp(0) * getp(1));
      pc += 4;
    } else if (opcode == 3) {
      setp(0, input());
      pc += 2;
    } else if (opcode == 4) {
      output(getp(0));
      pc += 2;
    } else if (opcode == 5) {
      if(getp(0)) {
        pc = getp(1);
      } else {
        pc += 3;
      }
    } else if (opcode == 6) {
      if(!getp(0)) {
        pc = getp(1);
      } else {
        pc += 3;
      }
    } else if (opcode == 7) {
      setp(2, getp(0) < getp(1));
      pc += 4;
    } else if (opcode == 8) {
      setp(2, getp(0) == getp(1));
      pc += 4;
    } else if (opcode == 9) {
      incbase(getp(0));
      pc += 2;
    } else {
      printf "FAIL at pc=%d, opcode=%d\n%s\n", pc, opcode, $0 >> "/dev/stderr"
      exit 1;
    }
  }
  exit
}
