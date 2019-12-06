BEGIN {
  FS = ",";
}

function abs(x) {
  if (x < 0) return -x;
  return x;
}

{
  x = 0;
  y = 0;
  steps = 0;
  for(n = 1; n <= NF; n++) {
    cmd = $n;
    dir = substr(cmd, 1, 1);
    len = int(substr(cmd, 2));
    if (dir == "L") {
      dx = -1;
      dy = 0;
    } else if (dir == "R") {
      dx = 1;
      dy = 0;
    } else if (dir == "U") {
      dx = 0;
      dy = 1;
    } else if (dir == "D") {
      dx = 0;
      dy = -1;
    }
    for(i = 0; i < len; i++) {
      x += dx;
      y += dy;
      steps++;

      key = x "_" y;

      if (NR == 1) {
        if (!points[key]) {
          points[key] = steps;
        }
      } else {
        if (points[key]) {
          print steps + points[key];
        }
      }
    }
  }
}

END {
}
