#! /usr/bin/env LANG=C gawk --lint=no-ext --bignum -f

@include "common"

BEGIN {
  FS = "";

  delete g_space;
  g_xmin = 0;
  g_ymin = 0;

  g_rating = 0;
  g_power = 1;

  delete g_ratings;
}

function parse(      x, y) {
  g_xmax = NF - 1;
  y = NR - 1;
  g_ymax = y;
  for(x=0; x<NF; x++) {
    ch = $(x + 1);
    g_space[x, y] = ch;
  }
}

function rate(     x, y, rating, power) {
  rating = 0;
  power = 1;
  for(y=g_ymin; y<=g_ymax; y++) {
    for(x=g_xmin; x<=g_xmax; x++) {
      if(g_space[x, y] == "#") {
        rating += power;
      }
      power *= 2;
    }
  }
  return rating;
}

function print_space(     x, y, h) {
  print "SPACE:";
  for(y=g_ymin; y<=g_ymax; y++) {
    for(x=g_xmin; x<=g_xmax; x++) {
      printf "%s", g_space[x, y];
    }
    printf "\n";
  }
}

function get(x, y) {
  return (x>= g_xmin) && (y>= g_ymin) &&(x<= g_xmax) &&(y<= g_xmax) &&g_space[x,y] == "#";
}

function step(     x,y,new_space) {
  delete new_space;
  for(y=g_ymin; y<=g_ymax; y++) {
    for(x=g_xmin; x<=g_xmax; x++) {
      neighbors = get(x-1, y) + get(x+1, y) + get(x, y-1) + get(x, y+1);
      if(get(x,y) == 1 && neighbors != 1) {
        new_space[x,y] = ".";
      } else if(get(x,y) == 0 && (neighbors == 1 || neighbors == 2)) {
        new_space[x,y] = "#";
      } else {
        new_space[x,y] = g_space[x,y];
      }
    }
  }
  copyarray(new_space, g_space);
}

{
  parse();
}

function scan(     steps, rating) {
  steps = 0;
  printf "\nInitial state:\n";
  while(1) {
    print_space();
    rating = rate();
    printf "Rating is %d\n", rating;
    if(rating in g_ratings) {
      printf "Rating %d (from step %d) repeats after %d steps\n", rating, g_ratings[rating], steps;
      exit 0;
    } else {
      g_ratings[rating] = steps;
    }
    step();
    steps++;

    printf "\nAfter %d minute%s:\n", steps, (steps > 1 ? "s":"");
  }
}

END {
  scan();
  exit 0;
  if(0) {
  }
}
