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

{
  set(1, noun);
  set(2, verb);
  while(1) {
    opcode = int(get(pc));
    if(opcode == 99) {
      break;
    } else if (opcode == 1) {
      set(get(pc + 3), get(get(pc + 1)) + get(get(pc + 2)));
      pc += 4;
    } else if (opcode == 2) {
      set(get(pc + 3), get(get(pc + 1)) * get(get(pc + 2)));
      pc += 4;
    } else {
      printf "FAIL at pc=%d, opcode=%d\n%s\n", pc, opcode, $0 >> "/dev/stderr"
      exit 1;
    }
  }
}

END {
  print noun, verb, get(0);
}
