#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

BEGIN {
  ENVIRON["LANG"] = "C";
  #FPAT = "[A-Z0-9]+";
  delete space;
  delete shortest;
  delete moves;
  debug=debug;

  x=0; y=0;
  minx=0;maxx=0;
  miny=0;maxy=0;

  glyphs[0] = " ";
  glyphs[1] = ".";
  glyphs[2] = "#";
  glyphs[3] = "O";

  delete moves;
  delete path;

  optimizing=0;
  best_path_length=99999999999999;
}

function copyarray(src, dest,      i) {
  delete dest;
  for(i in src) {
    dest[i] = src[i];
  }
}

function push_move(dir, nx, ny,       i) {
  i = length(moves);
  moves[i] = dir;
  path_i[i] = nx SUBSEP ny;
  path[nx,ny] = i;
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
  printf "sending %d\n", dir >> "/dev/stderr";
  nextx = x; nexty = y;
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

function draw_space(     nx, ny) {
  printf "SPACE:\n" >> "/dev/stderr";
  for(ny=maxy; ny>=miny; ny--) {
    for(nx=minx; nx<=maxx; nx++) {
      if(nx == x && ny == y)
        printf "D" >> "/dev/stderr";
      else {
        if(nx == 0 && ny == 0)
          printf "X" >> "/dev/stderr";
        else if((nx, ny) in path)
          printf "*" >> "/dev/stderr";
        else if((nx, ny) in best_path)
          printf "•" >> "/dev/stderr";
        else if((nx, ny) in space)
          printf "%s", glyphs[int(space[nx, ny])] >> "/dev/stderr";
        else
          printf " " >> "/dev/stderr";
      }
    }
    printf "\n" >> "/dev/stderr";
  }
}

function backtrack(     dir) {
  printf "backtracking!\n" >> "/dev/stderr";
  if(length(moves) == 0) {
    printf "can't backtrack!\n" >> "/dev/stderr";
    return -1;
  }
  dir = pop_move();
  if(dir==1) return 2;
  if(dir==2) return 1;
  if(dir==3) return 4;
  if(dir==4) return 3;
}

function pick_dir(     dir, nx, ny) {
  if(optimizing) {
    if (space[x,y] == 3) {
      printf "at goal\n" >> "/dev/stderr";
      exhausted[x,y]=1;
      return backtrack();
    }
    if (length(moves) >= best_path_length) {
      printf "longer than best\n" >> "/dev/stderr";
      exhausted[x,y] = 1;
      return backtrack();
    }
    for(dir=1; dir<5; dir++) {
      nx = x; ny = y;
      if(dir == 1) { ny++; }
      if(dir == 2) { ny--; }
      if(dir == 3) { nx--; }
      if(dir == 4) { nx++; }
      if(!((nx, ny) in space)) {
        # unexplored: let's go!
        printf "found unknown\n" >> "/dev/stderr";
        push_move(dir, nx, ny);
        return dir;
      }
      if(space[nx,ny] == 2) {
        # hit a wall: move on
        continue;
      }
      # an explored cell lies at nx,ny. should we go there ?
      if((nx,ny) in path) {
        # it's already on the path : nope!
        continue;
      } else {
        # not on the path so far.
        if(!((nx, ny) in exhausted)) {
          printf "found unexhausted\n" >> "/dev/stderr";
          push_move(dir, nx, ny);
          return dir;
        }
      }
    }
    # could not find interesting dir. backtrack.
    printf "exhausted %d,%d\n", x, y >> "/dev/stderr";
    exhausted[x,y]=1;
    return backtrack();
  } else {
    for(dir=1; dir<5; dir++) {
      nx = x; ny = y;
      if(dir == 1) { ny++; }
      if(dir == 2) { ny--; }
      if(dir == 3) { nx--; }
      if(dir == 4) { nx++; }
      if(!((nx, ny) in space)) {
        printf "found unknown\n" >> "/dev/stderr";
        push_move(dir, nx, ny);
        return dir;
      }
    }
    return backtrack();
  }
}

/^CTS$/ {
  printf "got CTS\n" >> "/dev/stderr";
  d=pick_dir();
  if(d<1) exit;
  move(d);
  next;
}

{
  status=$1;
  printf "at %d %d %d\n", nextx, nexty, status >> "/dev/stderr";
  if(status == 0) { pop_move(); space[nextx,nexty] = 2; } # wall
  if(status == 1) { space[nextx,nexty] = 1; x=nextx; y=nexty; } # empty
  if(status == 2) {
    space[nextx,nexty] = 3;
    x=nextx;
    y=nexty;
    optimizing = 1;
    if(best_path_length > length(moves)) {
      best_path_length = length(moves);
      printf "best path now %d\n", best_path_length >> "/dev/stderr";
      copyarray(path, best_path);
    }
  }

  printf "now at %d,%d\n", x, y >> "/dev/stderr";
  draw_space();
}



END {
  printf "found oxygen at %d,%d\n", x, y >> "/dev/stderr";

  close("/dev/stderr");
}
