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
  inputlen = NF;
  printf "input list length is %d\n", inputlen;
  for(i=1;i<=NF;i++) {
    printf "%d %d\n", i, $i;
  }
  offset = 0 + substr($0, 1, 7);
  printf "offset is %d\n", offset;
  virtuallen = inputlen * 10000;
  printf "virtual list length is %d\n", virtuallen;
  taillen = virtuallen - offset;
  printf "tail length is %d\n", taillen;
  for(i=0; i<taillen; i++) {
    currentlist[i] = $(1 + ((i + offset) % inputlen));
    # printf "%d", currentlist[i];
  }
  printf "\n";
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
  for(i=0; i<8; i++) {
    printf "%d", l[i];
  }
  printf "\n";
}

function abs(x) {
  return x < 0 ? -x : x;
}

function buildphase(          outindex, elt) {
  elt = currentlist[taillen - 1];
  for(outindex=taillen - 2; outindex>=0; outindex--) {
    # printf "[%d] %d = %d + %d\n", outindex, (elt + currentlist[outindex]) % 10, elt, currentlist[outindex];
    elt = (elt + currentlist[outindex]) % 10;
    currentlist[outindex] = elt;
  }
  # printf "\n"
}

function loop(     step) {
  step = 0;
  while(step<=steps) {
    printf "step %d ", step;
    printlist(currentlist);
    buildphase();
    # copyarray(nextlist, currentlist);
    step++;
  }
}

function printmatrix(n,     i, j) {
  for(j=0; j<n; j++) {
    for(i=0; i<n; i++) {
      printf "%2d ", patternfor(i, j);
    }
    printf "\n";
  }
}


END {
  loop();
  #printmatrix(steps);

  close("/dev/stderr");
}

