#! /usr/bin/env LANG=C /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

@include "common"
@include "ord"

BEGIN {
  ENVIRON["LANG"] = "C";
  printf "" >> "/dev/stderr";
}

function run_intcode(input,    output, ascii_output, cmd) {
  cmd = "gawk -f ./intcode.awk -v ctscode=0 -v debug=1 -v CODE=day21.txt 2>/tmp/intcode-debug.txt";
  if(debug>2) printf "sending: %s\n", input >> "/dev/stderr";
  printf "%s", input |& cmd;
  fflush(cmd);
  ascii_output = "";
  while( (cmd |& getline output) > 0) {
    if(debug>2) printf "received: %s\n", output >> "/dev/stderr";
    ascii_output = ascii_output chr(output);
  }
  close(cmd);
  return ascii_output;
}

function process(    input, input_ints, out, i) {
  out="";
  input = "NOT J J\nAND A J\nAND B J\nAND C J\nNOT J J\nAND D J\nWALK\n";
  delete input_a;

  input_ints = "";
  for(i=1; i<=length(input); i++) {
    input_ints = input_ints ord(substr(input, i, 1)) "\n";
  }

  out = run_intcode(input_ints);
  print out;
}

END {
  process();
  close("/dev/stderr");

  exit 0;
  if(0) {
    run_intcode();
  }
}
