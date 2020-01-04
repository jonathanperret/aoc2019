#! /usr/bin/env LANG=C gawk --lint=no-ext --bignum -f

@include "common"

function receive_one(address,    output) {
  if( (g_cmds[address] |& getline output) <= 0) {
    printf "fatal: no output from computer %d\n", address >> "/dev/stderr";
    exit 1;
  }
  if(debug>2) printf "received from %d: %s\n", address, output >> "/dev/stderr";
  return output;
}

function send_one(address, value,     output, cmd) {
  if(address == 255) {
    if(debug>2) printf "sending to NAT: %s\n", value >> "/dev/stderr";
    send_to_nat(value);
    return;
  }

  g_queues[address] = g_queues[address] value " ";
  if(debug>2) printf "queue for %d is now '%s'\n", address, g_queues[address] >> "/dev/stderr";
}

function receive_from_computer(address,   output, cmd, dest, queue, first) {
  cmd = g_cmds[address];

  if((cmd |& getline output) <=0) {
    printf "fatal: no output from computer %d\n", address >> "/dev/stderr";
    exit 1;
  }

  if(output == "CTS") {
    if(length(g_queues[address]) > 0) {
      pos = index(g_queues[address], " ");
      first = substr(g_queues[address], 1, pos - 1);
      if(debug>2) printf "got %d from queue for %d\n", first, address >> "/dev/stderr";
      g_queues[address] = pos < length(g_queues[address]) ? substr(g_queues[address], pos + 1, length(g_queues[address]) - pos) : "";
      if(debug>2) printf "queue for %d is now '%s'\n", address, g_queues[address] >> "/dev/stderr";
    } else {
      if(debug>2) printf "queue for %d is empty\n", address >> "/dev/stderr";
      first = -1;
    }
    if(debug>2) printf "sending to %d: %s\n", address, first >> "/dev/stderr";
    printf "%s\n", first |& cmd;
    fflush(cmd);
    return length(g_queues[address]) > 0;
  } else {
    dest = output;
    x = receive_one(address);
    y = receive_one(address);
    if(debug>1) printf "got %d,%d from %d for %d\n", x, y, address, dest >> "/dev/stderr";

    send_one(dest, x);
    send_one(dest, y);
    return 1;
  }
}

function start_computer(address,    input, output, cmd) {
  cmd = "gawk -f ./intcode.awk -v ctscode=CTS -v debug=1 -v CODE=day23.txt 2>/tmp/intcode-debug-" address ".txt";
  g_cmds[address] = cmd

  if (debug) printf "starting: %s\n", cmd >> "/dev/stderr";

  if((cmd |& getline output) <=0) {
    printf "fatal: no output from computer %d\n" >> "/dev/stderr";
    exit 1;
  }

  if(output != "CTS") {
    printf "fatal: no CTS from computer %d, got %s instead\n", address, output >> "/dev/stderr";
    exit 1;
  }

  input = address;
  if(debug>1) printf "sending to %d: %s\n", address, input >> "/dev/stderr";

  printf "%s\n", input |& cmd;
  fflush(cmd);

  g_queues[address] = "";
}

function start_computers(    address) {
  for(address=0; address<50; address++) {
    start_computer(address);
  }
}

function stop_computers(    address) {
  for(address in g_cmds) {
    close(g_cmds[address]);
  }
}

function process_network(    address, network_busy, computer_busy) {
  network_busy = 0;
  for(address in g_cmds) {
    computer_busy = 1;
    while(computer_busy) {
      computer_busy = receive_from_computer(address);
      network_busy = network_busy || computer_busy;
    }
  }
  if(!network_busy) {
    if(g_nat_got_packet) {
      # g_nat_got_packet = 0;
      if(g_nat_y == g_nat_last_y) {
        printf "NAT about to send same Y as last: %d\n", g_nat_y >> "/dev/stderr";
        exit 0;
      }
      g_nat_last_y = g_nat_y;
      printf "NAT sending %d,%d\n", g_nat_x, g_nat_y >> "/dev/stderr";
      send_one(0, g_nat_x);
      send_one(0, g_nat_y);
    } else {
      printf "no NAT packet to send yet\n" >> "/dev/stderr";
      # exit 1;
    }
  }
}

function send_to_nat(value) {
  if(g_nat_expecting_x) {
    g_nat_expecting_x = 0;
    g_nat_x = value;
  } else {
    g_nat_expecting_x = 1;
    g_nat_y = value;
    g_nat_got_packet = 1;
    printf "NAT packet is %d,%d\n", g_nat_x, g_nat_y >> "/dev/stderr";
  }
}

BEGIN {
  printf "" >> "/dev/stderr";

  delete g_cmds;
  delete g_queues;

  g_nat_x = -1;
  g_nat_y = -1;
  g_nat_last_y = -2;
  g_nat_expecting_x = 1;
  g_nat_got_packet = 0;

  start_computers();

  printf "Started computers\n" >> "/dev/stderr";

  g_steps = 0;

  while(1) {
    printf "Step %d\n", g_steps >> "/dev/stderr";
    process_network();
    g_steps++;
  }

  exit 0;
  if(0) {
  }
}

END {
  close("/dev/stderr");
  stop_computers();
}
