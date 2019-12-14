#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

BEGIN {
  ENVIRON["LANG"] = "C";
  FPAT = "[A-Z0-9]+";
}

function parse(out_mat, out_q, i) {
  out_q = $(NF - 1);
  out_mat = $(NF);

  out_quantity[out_mat] = out_q;
  for(i = 1; i < NF - 1; i+=2) {
    reqs[out_mat][$(i + 1)] = $i;
  }
}

{
  parse();
}

function find_needed(out_mat,    react_count, needed_q, inputstr, inputlist, out_q, in_mat) {
  if(!(out_mat in reqs)) {
    return 0;
  }
  needed_q = neededqs[out_mat];
  out_q = out_quantity[out_mat];
  react_count = int(needed_q / out_q);
  if(needed_q % out_q > 0) react_count++;
  for(in_mat in reqs[out_mat]) {
    neededqs[in_mat] = (in_mat in neededqs ? neededqs[in_mat] : 0) + reqs[out_mat][in_mat] * react_count;
  }
  neededqs[out_mat] -= react_count * out_q;
  return 1;
}

function produce_needed(     mat, again) {
  again = 1;
  while(again) {
    again = 0;
    for(mat in reqs) {
      if(mat in neededqs && neededqs[mat] > 0) {
        again += find_needed(mat);
      }
    }
    if(debug) {
      for(mat in neededqs) {
        if(neededqs[mat] < 0) {
          printf "%s remaining %d\n", mat, -neededqs[mat];
        }
      }
      print "-------";
    }
  }
}

function copyarray(src, dest,      i) {
  delete dest;
  for(i in src) {
    dest[i] = src[i];
  }
}

function produce_fuel(fuelq,       mat, prevneededqs, neededore) {
  copyarray(neededqs, prevneededqs);
  neededqs["FUEL"] = fuelq;
  produce_needed();
  if(neededqs["ORE"] > 0) {
    # rollback
    copyarray(prevneededqs, neededqs);
    return 0;
  } else {
    return fuelq;
  }
}

END {
  availableore = 1000000000000;
  neededqs["ORE"] = -availableore;
  totalfuel = 0;
  fuelincr = 1;
  while(fuelincr < availableore) fuelincr *= 2;
  while(fuelincr>0) {
    printf "produced %d fuel, remaining %d ore, trying to produce %d more\n", totalfuel, -neededqs["ORE"], fuelincr;
    totalfuel += produce_fuel(fuelincr);
    fuelincr = int(fuelincr/2);
  }
  printf "produced %d fuel, remaining %d ore\n", totalfuel, -neededqs["ORE"];
}
