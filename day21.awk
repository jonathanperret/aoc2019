#! /usr/bin/env LANG=C /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

@include "common"
@include "ord"

BEGIN {
  ENVIRON["LANG"] = "C";
  printf "" >> "/dev/stderr";
  g_input = "";
}

function run_intcode(input,    output, ascii_output, cmd, input_ints, i) {
  input_ints = "";
  for(i=1; i<=length(input); i++) {
    input_ints = input_ints ord(substr(input, i, 1)) "\n";
  }

  cmd = "gawk -f ./intcode.awk -v ctscode=0 -v debug=1 -v CODE=day21.txt 2>/tmp/intcode-debug.txt";
  if(debug>2) printf "sending: %s\n", input >> "/dev/stderr";
  printf "%s", input_ints |& cmd;
  fflush(cmd);
  ascii_output = "";
  while( (cmd |& getline output) > 0) {
    if(debug>2) printf "received: %s\n", output >> "/dev/stderr";
    if(output>127) {
      ascii_output = ascii_output output;
    } else {
      ascii_output = ascii_output chr(output);
    }
  }
  close(cmd);
  return ascii_output;
}

function process(input,    out, i) {
  out = run_intcode(input);
  print out;
}

/^[A-Z]/ {
  g_input = g_input $0 "\n";
}

END {
  process(g_input);
  close("/dev/stderr");

  exit 0;
  if(0) {
    run_intcode();
  }
}
