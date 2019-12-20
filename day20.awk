#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

@include "common"

BEGIN {
  ENVIRON["LANG"] = "C";
  printf "" >> "/dev/stderr";
  FPAT = ".";
  g_letterCount = 0;
  delete g_portalPos;
  delete g_letters;
  delete g_space;

  g_xmin = 1;
  g_ymin = 1;
}

function parse(     i, labelname, labelpos) {
  for (i=1; i<=NF; i++) {
    if ($i ~ /[A-Z]/) {
      g_letterCount++;
      g_letters[i, NR] = $i;

      if((i-1, NR) in g_letters) {
        labelpos = (i-1) SUBSEP NR;
        labelname = g_letters[i-1, NR] $i;
        if(!(labelname in g_labels)) { g_labels[labelname] = labelpos; }
        if((i-2,NR) in g_space && g_space[i-2,NR] == ".") { g_space[i-2,NR] = labelname; } else { g_space[i+1,NR] = labelname; }
      }
      if((i, NR-1) in g_letters) {
        labelpos = i SUBSEP (NR-1);
        labelname = g_letters[i, NR-1] $i;
        if(!(labelname in g_labels)) { g_labels[labelname] = labelpos; }
        if((i,NR-2) in g_space && g_space[i,NR-2] == ".") { g_space[i,NR-2] = labelname; } else { g_space[i,NR+1] = labelname; }
      }
      g_space[i, NR] = " ";
    } else {
      if(!((i,NR) in g_space)) g_space[i, NR] = $i;
    }
  }
}

{
  parse();
}

function print_space(     x, y, h) {
  print "SPACE:";
  for(y=g_ymin; y<=g_ymax; y++) {
    for(x=g_xmin; x<=g_xmax; x++) {
      printf "%-2s", substr(g_space[x, y]g_space[x,y], 1, 2);
    }
    printf "\n";
  }
}

END {
  g_xmax = NF;
  g_ymax = NR;
  printf "%d letters seen (%d portals)\n", g_letterCount, g_letterCount / 4;
  print_space();
  close("/dev/stderr");
  if(0) {
  }
}
