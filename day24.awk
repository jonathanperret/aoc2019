#! /usr/bin/env LANG=C gawk --lint=no-ext --bignum -f

@include "common"

BEGIN {
  FS = "";

  g_xmin = 0;
  g_ymin = 0;
  g_zmin = 0;
  g_zmax = 0;

  g_rating = 0;
  g_power = 1;

  delete g_space;
}

function parse(      x, y) {
  g_xmax = NF - 1;
  y = NR - 1;
  g_ymax = y;
  for(x=0; x<NF; x++) {
    ch = $(x + 1);
    g_space[x, y, 0] = ch;
  }
}

function print_space(     x, y, z) {
  print "SPACE:";
  for(z=g_zmin; z<=g_zmax; z++) {
    printf "%-6d", z;
  }
  printf "\n";
  for(y=g_ymin; y<=g_ymax; y++) {
    for(z=g_zmin; z<=g_zmax; z++) {
      for(x=g_xmin; x<=g_xmax; x++) {
        printf "%s", (x == 2 && y == 2) ? "?" : g_space[x, y, z];
      }
      printf " ";
    }
    printf "\n";
  }
}

function get(x, y, z,     c) {
  c = (x>= g_xmin) && (y>= g_ymin) &&(x<= g_xmax) &&(y<= g_xmax) && (z>=g_zmin) && (z<=g_zmax) && g_space[x,y,z] == "#";
  if(debug>2) printf "[%d,%d,%d=%d]", x,y,z,c;
  return c;
}

function count_v_edge(x, z,    y, c) {
  if(debug) printf " [counting x=%d, y=*, z=%d -> %d]", x, z, c;
  c = 0;
  for(y=g_ymin; y<=g_ymax; y++) {
    c += get(x, y, z);
  }
  return c;
}

function count_h_edge(y, z,    x, c) {
  c = 0;
  for(x=g_xmin; x<=g_xmax; x++) {
    c += get(x, y, z);
  }
  if(debug) printf " [counting x=*, y=%d, z=%d -> %d]", y, z, c;
  return c;
}

function _count(x, y, z, dx, dy,     tx, ty) {
  tx = x + dx;
  ty = y + dy;
  if(tx>=g_xmin && tx <= g_xmax && ty >= g_ymin && ty <= g_ymax && (tx != 2 || ty != 2)) {
    return get(tx, ty, z);
  }
  if(tx == 2 && ty == 2) {
    if(dx<0) return count_v_edge(g_xmax, z + 1);
    if(dx>0) return count_v_edge(g_xmin, z + 1);
    if(dy<0) return count_h_edge(g_ymax, z + 1);
    if(dy>0) return count_h_edge(g_ymin, z + 1);
  }
  if(tx > g_xmax) return get(3, 2, z - 1);
  if(tx < g_xmin) return get(1, 2, z - 1);
  if(ty > g_ymax) return get(2, 3, z - 1);
  if(ty < g_ymin) return get(2, 1, z - 1);
  return 0;
}

function count(x, y, z, dx, dy,     tx, ty, c) {
  tx = x + dx;
  ty = y + dy;
  if(debug>1) printf "at %d,%d,%d for %d,%d,%d", tx, ty, z, x, y, z;
  c = _count(x, y, z, dx, dy);
  if(debug>1) printf " n=%d\n", c;
  return c;
}

function step(steps    ,x,y,z,new_zmin,new_zmax,new_space) {
  delete new_space;
  new_zmin = g_zmin;
  new_zmax = g_zmax;
  if(steps % 2 == 0) {
    new_zmin--;
    new_zmax++;
  }
  for(z=new_zmin; z<=new_zmax; z++) {
    for(y=g_ymin; y<=g_ymax; y++) {
      for(x=g_xmin; x<=g_xmax; x++) {

        state = get(x,y,z);

        if(x != 2 || y != 2) {
          neighbors = count(x, y, z, -1, 0) + count(x, y, z, 1, 0) + count(x, y, z, 0, -1) + count(x, y, z, 0, 1);
          if(debug) printf "for %d,%d,%d n=%d\n", x, y, z, neighbors;

          if(state == 1 && neighbors != 1) {
            state = 0;
          } else if(state == 0 && (neighbors == 1 || neighbors == 2)) {
            state = 1;
          }
        }

        new_space[x,y,z] = state ? "#" : ".";
      }
    }
  }

  g_zmin = new_zmin;
  g_zmax = new_zmax;
  copyarray(new_space, g_space);
}

{
  parse();
}

function scan(     steps, rating, bugs, x, y, z) {
  steps = 0;
  printf "\nInitial state:\n";
  while(steps<=200) {
    if(steps>0) {
      printf "\nAfter %d minute%s:\n", steps, (steps > 1 ? "s":"");
    }
    print_space();
    bugs = 0;
    for(z=g_zmin-1; z<=g_zmax+1; z++) {
      for(y=g_ymin; y<=g_ymax; y++) {
        for(x=g_xmin; x<=g_xmax; x++) {
          bugs += get(x,y,z);
        }
      }
    }
    printf "Counting %d bugs\n", bugs;

    step(steps);
    steps++;
  }
}

END {
  scan();
  exit 0;
  if(0) {
  }
}
