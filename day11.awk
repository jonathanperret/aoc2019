#! /usr/bin/awk -f

function output(n) {
  if (debug) printf "sending %d to brain\n", n >> "/dev/stderr";
  print n;
  fflush();
}

function get(x, y) {
  if ((x, y) in panels) {
    return int(panels[x, y]);
  }
  return 0;
}

function set(x, y, c) {
  panels[x, y] = c;

  if(x<xmin) xmin = x;
  if(y<ymin) ymin = y;

  if(x>xmax) xmax = x;
  if(y>ymax) ymax = y;
}

BEGIN {
  dir = 0; # up
  x = 0; y = 0;
  xmin = 99999999;
  ymin = 99999999;
  xmax = -99999999;
  ymax = -99999999;

  if(!startcolor) startcolor = 0;
  output(startcolor);
}

{
  color = $1;
  if(debug) printf "got color %d from brain\n", color >> "/dev/stderr";

  set(x, y, color);

  getline turn;
  if(debug) printf "got turn %d from brain\n", turn >> "/dev/stderr";

  if (turn == 0) { dir = (dir + 3) % 4; } else { dir = (dir + 1) % 4; }

  if(dir == 0) y += 1;
  if(dir == 1) x += 1;
  if(dir == 2) y -= 1;
  if(dir == 3) x -= 1;

  output(get(x, y));
  if(debug>1) dump_panels();
}

function dump_panels() {
  printf "%d %d %d %d\n", xmin, xmax, ymin, ymax >> "/dev/stderr";
  glyphs[0] = "  ";
  glyphs[1] = "██";

  for(py = ymax; py >= ymin; py--) {
    for(px = xmin; px <= xmax; px++) {
      printf "%s", glyphs[get(px, py)] >> "/dev/stderr";
    }
    printf "\n" >> "/dev/stderr";
  }
}

function sendpbmto(cmd) {
  printf "P1\n%d %d\n", xmax - xmin + 1, ymax - ymin + 1 | cmd;
  for(py = ymax; py >= ymin; py--) {
    for(px = xmin; px <= xmax; px++) {
      printf "%d ", get(px, py) | cmd;
    }
  }
}

END {
  printf "painted %d\n", length(panels) >> "/dev/stderr";
  dump_panels();
  sendpbmto("convert -trim -bordercolor white -border 1 - -|tesseract --psm 13 --dpi 70 stdin stdout|head -1 >&2");
}
