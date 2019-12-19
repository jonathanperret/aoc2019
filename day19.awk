#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

@include "common"

BEGIN {
  ENVIRON["LANG"] = "C";
  delete g_space;
  g_xmin = 9999999;
  g_ymin = 9999999;
  g_xmax = -9999999;
  g_ymax = -9999999;
  printf "" >> "/dev/stderr";
}

{
  g_space[$1,$2] = $3 ? "#" : ".";
  if($1 < g_xmin) g_xmin = $1;
  if($2 < g_ymin) g_ymin = $2;
  if($1 > g_xmax) g_xmax = $1;
  if($2 > g_ymax) g_ymax = $2;
}

function print_space(     x, y, colcnts, linecnt, printedxmarker) {
  print "SPACE:";
  printf "     %-5d", g_xmin;
  for(x=g_xmin+5; x<g_xmax-2; x++) printf " ";
  printf "%-5d\n", g_xmax;
  for(x=g_xmin; x<=g_xmax; x++) {
    colcnts[x] = 0;
  }
  for(y=g_ymin; y<=g_ymax; y++) {
    printf "%-5d", y;
    linecnt = 0;
    for(x=g_xmin; x<=g_xmax; x++) {
      printf "%s", substr(g_space[x,y], 1, 1);
      if(g_space[x,y] == "#") {
        linecnt += g_space[x,y] == "#";
        colcnts[x] ++;
      }
    }
    printf " %-5d\n", linecnt;
  }
  printf "     %-5d", g_xmin;
  printedxmarker = 0;
  for(x=g_xmin+5; x<g_xmax-2; x++) {
    if(colcnts[x] >= 100 && ! printedxmarker) {
      printf "^ %-5d", x;
      x+=6;
      printedxmarker = 1;
    } else {
      printf " ";
    }
  }
  printf "%-5d\n", g_xmax;
}

END {
  print_space();
  close("/dev/stderr");
  if(0) {
    print_space();
  }
}
