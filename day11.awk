#! /usr/bin/awk -f

function output(n) {
  printf "sending %d to brain\n", n >> "/dev/stderr";
  print n;
  fflush();
}

BEGIN {
  dir = 0; # up
  x = 0; y = 0;
  painted = 0;

  output(0);
}

{
  color = $1;

  printf "got color %d from brain\n", color >> "/dev/stderr";

  loc = x"_"y;
  printf "painting %d,%d (%s) with %d\n", x, y, loc, color >> "/dev/stderr";
  if(!visited[loc]) {
    printf "painting new panel!\n" >> "/dev/stderr";
    visited[loc] = 1;
  }
  printf "previous panel color at (%d,%d) is %d\n", x, y, panels[loc] >> "/dev/stderr";
  panels[loc] = color;

  getline turn;

  printf "got turn %d from brain\n", turn >> "/dev/stderr";

  if (turn == 0) { dir = (dir + 3) % 4; } else { dir = (dir + 1) % 4; }

  printf "now at %d,%d facing %d\n", x, y, dir >> "/dev/stderr";

  if(dir == 0) y += 1;
  if(dir == 1) x += 1;
  if(dir == 2) y -= 1;
  if(dir == 3) x -= 1;

  printf "now at %d,%d facing %d painted %d = %d\n", x, y, dir, length(visited), length(panels) >> "/dev/stderr";

  loc = x"_"y;
  output(int(panels[loc]));
}

END {
  printf "painted %d\n", length(visited) >> "/dev/stderr";
}
