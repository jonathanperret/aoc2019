#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

BEGIN {
  ENVIRON["LANG"] = "C";
  delete space;
  delete shortest;
  delete moves;
  debug=debug;

  dronex=0; droney=0;
  minx=0;maxx=0;
  miny=0;maxy=0;

  glyphs[0] = " ";
  glyphs[1] = ".";
  glyphs[2] = "#";
  glyphs[3] = "O";

  delete moves;
  delete path;
}

function push_move(dir, x, y,       i) {
  i = length(moves);
  moves[i] = dir;
  path_i[i] = x SUBSEP y;
  path[x,y] = i;
}

function pop_move(        i, pi, dir) {
  i = length(moves) - 1;
  dir = moves[i];
  delete moves[i];
  pi = path_i[i];
  delete path_i[i];
  delete path[pi];
  return dir;
}

function move(dir) {
  if(debug) printf "sending %d\n", dir >> "/dev/stderr";
  nextx = dronex; nexty = droney;
  if(dir == 1) { nexty++; }
  if(dir == 2) { nexty--; }
  if(dir == 3) { nextx--; }
  if(dir == 4) { nextx++; }

  if(nextx<minx) minx=nextx;
  if(nexty<miny) miny=nexty;
  if(nextx>maxx) maxx=nextx;
  if(nexty>maxy) maxy=nexty;

  print dir;
  fflush();
}

function draw_space(     x, y) {
  printf "SPACE:\n" >> "/dev/stderr";
  for(y=maxy; y>=miny; y--) {
    for(x=minx; x<=maxx; x++) {
      if(x == dronex && y == droney)
        printf "D" >> "/dev/stderr";
      else if(x == 0 && y == 0)
          printf "X" >> "/dev/stderr";
      else if((x, y) in shortest)
        printf "%d", shortest[x,y]%10 >> "/dev/stderr";
      else if((x, y) in space)
        printf "%s", glyphs[int(space[x, y])] >> "/dev/stderr";
      else
        printf " " >> "/dev/stderr";
    }
    printf "\n" >> "/dev/stderr";
  }
}

function backtrack(     dir) {
  if(debug) printf "backtracking!\n" >> "/dev/stderr";
  if(length(moves) == 0) {
    if(debug) printf "can't backtrack!\n" >> "/dev/stderr";
    return -1;
  }
  dir = pop_move();
  if(dir==1) return 2;
  if(dir==2) return 1;
  if(dir==3) return 4;
  if(dir==4) return 3;
}

function pick_dir(     dir, x, y) {
  for(dir=1; dir<5; dir++) {
    x = dronex; y = droney;
    if(dir == 1) { y++; }
    if(dir == 2) { y--; }
    if(dir == 3) { x--; }
    if(dir == 4) { x++; }
    if(!((x, y) in exhausted) && !((x,y) in path)) {
      if(debug) printf "found unknown\n" >> "/dev/stderr";
      push_move(dir, x, y);
      return dir;
    }
  }
  exhausted[dronex, droney] = 1;
  return backtrack();
}

function find_best_path(     distance, x, y, xya, xy, again) {
  again = 1;
  distance = 0;
  shortest[0, 0] = 0;
  while(again) {
    again = 0;
    for(xy in space) {
      if(!(xy in shortest)) continue;
      if(shortest[xy] != distance) continue;

      split(xy, xya, SUBSEP);
      x = xya[1];
      y = xya[2];

      again += expand_fringe(x+1, y, distance);
      again += expand_fringe(x-1, y, distance);
      again += expand_fringe(x, y+1, distance);
      again += expand_fringe(x, y-1, distance);
    }
    distance++;
    if(debug>=2) draw_space();
  }
  printf "shortest path to oxygen is %d long\n", shortest[oxygenx, oxygeny] >> "/dev/stderr";
  delete shortest;
}

function expand_fringe(x, y, distance) {
  if(!((x,y) in space)) return 0;
  if(space[x,y] == 2) return 0;
  if((x,y) in shortest) return 0;
  shortest[x,y] = distance + 1;
  return 1;
}

function next_input(     d) {
  d=pick_dir();
  if(d<1) {
    printf "found oxygen at %d,%d\n", oxygenx, oxygeny >> "/dev/stderr";
    draw_space();
    find_best_path();
    fill_oxygen();
    exit;
  } else {
    move(d);
  }
}

/^CTS$/ {
  if(debug) printf "got CTS\n" >> "/dev/stderr";
  next_input();
  next;
}

function process_status(status) {
  if(status == 0) { pop_move(); exhausted[nextx,nexty] = 1; space[nextx,nexty] = 2; } # wall
  if(status == 1) { space[nextx,nexty] = 1; dronex=nextx; droney=nexty; } # empty
  if(status == 2) {
    oxygenx = nextx;
    oxygeny = nexty;
    space[nextx,nexty] = 3;
    dronex=nextx;
    droney=nexty;
  }

  if(debug) printf "now at %d,%d\n", dronex, droney >> "/dev/stderr";
  if(debug>=2) draw_space();
}

{
  process_status(int($1));
}

function fill_at(x, y) {
  if((x,y) in space) {
    if(space[x,y] == 1) {
      space[x,y] = 9; # will become oxygen
      return 1;
    }
  }
  return 0;
}

function fill_oxygen(    xy, xya, x, y, time, again) {
  time = 0;
  again = 1;
  while(again) {
    time++;
    again=0;
    for(xy in space) {
      split(xy, xya, SUBSEP);
      x = xya[1];
      y = xya[2];
      if(space[xy] == 3) {
        # printf "filling from %d,%d\n", x, y >> "/dev/stderr";
        again += fill_at(x+1, y  );
        again += fill_at(x-1, y  );
        again += fill_at(x  , y+1);
        again += fill_at(x  , y-1);
      }
    }
    # fixup "to be oxygen" nodes to be oxygen
    for(xy in space) {
      if(space[xy] == 9) {
        space[xy] = 3;
      }
    }
    if(!again) time--;
    if(debug>=2) {
      printf "after %d minutes:\n", time >> "/dev/stderr";
      draw_space();
    }
  }
  printf "Oxygen fills space in %d minutes.\n", time >> "/dev/stderr";
}

END {
  close("/dev/stderr");
}
