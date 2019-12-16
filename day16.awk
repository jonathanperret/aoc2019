#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

BEGIN {
  ENVIRON["LANG"] = "C";
  FS="";
  phase = 0;
  delete currentlist;
  delete nextlist;

  pattern[0] = 0;
  pattern[1] = 1;
  pattern[2] = 0;
  pattern[3] = -1;
}

function patternfor(outindex, n,    patoffset, patmult, patlen, patpos) {
  patoffset = 1;
  patmult = 1 + outindex;
  patlen = length(pattern);
  patpos = int((n + patoffset) / patmult) % patlen;
  return pattern[patpos];
}

function parse(     i) {
  for(i=1; i<=NF; i++) {
    currentlist[i-1] = $i;
  }
}

{
  parse();
}

function copyarray(src, dest,      i) {
  delete dest;
  for(i in src) {
    dest[i] = src[i];
  }
}

function printlist(l,   i) {
  for(i=0; i<length(l); i++) {
    printf "%d", l[i];
  }
  printf "\n";
}

function abs(x) {
  return x < 0 ? -x : x;
}

function buildphase(          outindex, inindex, elt) {
  printlist(currentlist);
  nextlist[1] = currentlist[1];

  for(outindex=0; outindex<length(currentlist); outindex++) {
    elt = 0;
    for(inindex=0; inindex<length(currentlist); inindex++) {
      # printf "for out %d at pos %d=(%d)\n", outindex, inindex, patternfor(outindex, inindex);
      # printf "%d * %d + ", currentlist[inindex], patternfor(outindex, inindex) >> "/dev/stderr";
      elt += currentlist[inindex] * patternfor(outindex, inindex);
    }
    # printf " = %d\n", elt >> "/dev/stderr";
    nextlist[outindex] = abs(elt % 10);
  }
}

function loop(     step) {
  step = 0;
  while(step<=100) {
    printf "step %d ", step;
    buildphase();
    copyarray(nextlist, currentlist);
    step++;
  }
}


END {
  loop();

  close("/dev/stderr");
}
