#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

BEGIN {
  ENVIRON["LANG"] = "C";
  FS="";
  delete currentlist;
}

function parse(     i) {
  inputlen = NF;
  printf "input list length is %d\n", inputlen >> "/dev/stderr";
  offset = 0 + substr($0, 1, 7);
  printf "offset is %d\n", offset >> "/dev/stderr";
  virtuallen = inputlen * 10000;
  printf "virtual list length is %d\n", virtuallen >> "/dev/stderr";
  taillen = virtuallen - offset;
  printf "tail length is %d\n", taillen >> "/dev/stderr";
  for(i=0; i<taillen; i++) {
    currentlist[i] = $(1 + ((i + offset) % inputlen));
    # printf "%d", currentlist[i];
  }
}

{
  parse();
}


function printlist(l,   i) {
  for(i=length(l) - 1; i>=0; i--) {
    printf "%d\n", l[i];
  }
}

END {
  printlist(currentlist)
  close("/dev/stderr");
}

