#! /usr/bin/awk -f

BEGIN {
  FS = "";
}

{
  if(!width) width = NF;
  y=NR-1;
  for(x=0;x<width;x++) {
    loc = y*width +x;
    isasteroid=($(x+1) == "#");
    if(isasteroid) { map[loc]=1 }
    if(debug && isasteroid) {
      printf "found one at %d, %d\n", x, y;
    }
  }
}

function scan(x0, y0, dx, dy) {
  if(debug>1) printf " scan %d,%d\n", dx, dy;
  for(y=y0;y>=0 && y<height;y+=dy) {
    for(x=x0;x>=0 && x<width;x+=dx) {
      if(debug>1) printf "  %d,%d\n", x, y;
      if(x == startx && y == starty) continue;
      loc = y*width + x;
      if(loc in visited) {
        if(debug>1) printf "   visited from %s\n", visited[loc];
        continue;
      }
      vecx = x - startx;
      vecy = y - starty;
      if(debug>1) printf "   vector is %d,%d\n", vecx, vecy;
      testx = x;
      testy = y;
      seen = 0;
      while(testx>=0 && testx<width && testy>=0 && testy<height) {
        loc = testy*width + testx;
        if(loc in map) seen++;
        visited[loc] = x","y;
        testx += vecx;
        testy += vecy;
      }
      visible += (seen > 0);
      if(debug>1) {
        printf "   looking to %d,%d seeing %d visible now %d\n", x, y, seen, visible;
      }
    }
  }
}

END {
  height = NR;

  print width, height, length(map);

  for(startx=0;startx<width;startx++) {
    for(starty=0;starty<height;starty++) {
      # if(startx!=3 || starty!=4) continue;
      if(debug)
        printf "testing %d,%d\n", startx, starty;
      loc = starty*width+startx;
      if(!(loc in map)) continue;
      delete visited;
      visible = 0;
      scan(startx, starty, 1, 1);
      scan(startx, starty, -1, 1);
      scan(startx, starty-1, 1, -1);
      scan(startx-1, starty-1, -1, -1);
      printf "from %d,%d ", startx, starty;
      printf "seeing %d\n", visible
    }
  }

}
