#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

@include "common"

BEGIN {
  ENVIRON["LANG"] = "C";
  delete g_space;
  printf "" >> "/dev/stderr";
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

function makelines(    y) {
  g_xstart = 0;
  g_xend = 0;
  g_xmin = 845;
  g_ymin = 660;
  g_xmax = g_xmin + 300;
  g_ymax = g_ymin + 300;
  for(y=g_ymin; y<=g_ymax; y++) {
    printf "y=%d\n", y >> "/dev/stderr";
    makeline(y);
  }
}

function makeline(y,   x) {
  while(getbeam(g_xstart, y) == 0) {
    g_xstart++;
  }
  if(g_xend < g_xstart) {
    g_xend = g_xstart;
  }
  while(getbeam(g_xend, y) == 1) {
    g_xend++;
  }
  printf "y=%d: %d - %d\n", y, g_xstart, g_xend >> "/dev/stderr";
  for(x=g_xmin; x<=g_xmax; x++) {
    if(x<g_xstart || x>=g_xend) {
      g_space[x,y] = ".";
    } else {
      g_space[x,y] = "#";
    }
  }
}

function getbeam(x, y,    out, cmd) {
  # printf "getting %d,%d", x, y >> "/dev/stderr";
  cmd = "gawk -f ./intcode.awk -v ctscode=0 -v debug=0 -v CODE=day19.txt 2>/tmp/debug.txt";
  printf "%d\n%d\n", x, y |& cmd;
  fflush(cmd);
  cmd |& getline out;
  close(cmd);
  # printf ": %s\n", out >> "/dev/stderr";
  return out + 0;
}

function fit_square(    x,y) {
  for(y=g_ymin; y<=g_ymax-100; y++) {
    for(x=g_xmin; x<=g_xmax-100; x++) {
      if(g_space[x,y] == "#" && g_space[x+99,y] == "#" && g_space[x+99,y+99] == "#" &&g_space[x,y+99] == "#") {
        printf "Fits at %d, %d\n", x,y  >> "/dev/stderr";
        return;
      }
    }
  }
}

BEGIN {
  makelines();
  print_space();
  fit_square();
  close("/dev/stderr");
  exit 0;
  if(0) {
    makelines();
    print_space();
  }
}
