#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=invalid --bignum -f

BEGIN {
  ENVIRON["LANG"] = "C";
  FS = " => "
  nmats = 0;
  currentmat = 0;
  delete neededqs;
}

function parse(inputstr, outputstr,      out_q, out_q_mat) {
  split(outputstr, out_q_mat, " ");
  out_q = out_q_mat[1];
  out_mat = out_q_mat[2];
  reqs[out_mat] = inputstr;
  out_quantity[out_mat] = out_q;
}

{
  parse($1, $2);
}

function find_needed(mat,    react_count, needed_q, inputstr, inputlist, out_q, i, in_mat_q_str, in_mat_q, in_mat, in_q) {
  if(!(mat in reqs)) {
    return 0;
  }
  needed_q = neededqs[mat];
  inputstr = reqs[mat];
  split(inputstr, inputlist, ", ");
  out_q = out_quantity[mat];
  react_count = int(needed_q / out_q);
  if(needed_q % out_q > 0) react_count++;
  for(i in inputlist) {
    in_mat_q_str = inputlist[i];
    split(in_mat_q_str, in_mat_q, " ");
    in_q = in_mat_q[1];
    in_mat = in_mat_q[2];
    if(!(in_mat in neededqs))
      neededqs[in_mat] = 0;
    neededqs[in_mat] += in_q * react_count;
    if(!(in_mat in usedqs))
      usedqs[in_mat] = 0;
    usedqs[in_mat] += in_q * react_count;
  }
  neededqs[mat] -= react_count * out_q;
  return 1;
}

function produce_needed(     mat) {
  while(1) {
    again = 0;
    for(mat in neededqs) {
      if(neededqs[mat] > 0 && mat in reqs) {
        again += find_needed(mat);
        break;
      }
    }
    for(mat in neededqs) {
      if(neededqs[mat] < 0) {
        if(debug) printf "%s produced %d remaining %d\n", mat, usedqs[mat], -neededqs[mat];
      }
    }
    if(!again) break;
    if(debug) print "-------";
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
    totalfuel += fuelq;
    return 1;
  }
}

END {
  totalfuel = 0;
  neededqs["ORE"] = -1000000000000;
  fuelincr = 16777216;
  while(fuelincr>0) {
    printf "produced %d, remaining %d, trying to produce %d more\n", totalfuel, -neededqs["ORE"], fuelincr;
    if(!produce_fuel(fuelincr)) {
      print "nope"
      fuelincr = int(fuelincr/2)
    }
  }
  # if(debug) close("/dev/stderr");
}
