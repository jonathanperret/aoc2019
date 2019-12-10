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
      # printf "found one at %d, %d\n", x, y;
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
      angle = atan2(-vecx-1e-40, vecy);
      if(debug>1) printf "   vector is %d,%d angle %f\n", vecx, vecy, angle;
      testx = x;
      testy = y;
      seen = 0;
      distance = 1;
      while(testx>=0 && testx<width && testy>=0 && testy<height) {
        loc = testy*width + testx;
        visited[loc] = x","y;
        if(loc in map) {
          seen++;
          distances[loc] = distance;
          angles[loc] = angle;
          if(debug>1) {
            printf "    %d,%d distance %d angle %f\n", testx, testy, distance, angle;
          }
          distance++;
        }
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

function selectbase() {
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

END {
  height = NR;

  print width, height, length(map);

  if(!startx) startx = 26;
  if(!starty) starty = 29;

  delete visited;
  visible = 0;
  scan(startx, starty-1, 1, -1);
  scan(startx, starty, 1, 1);
  scan(startx, starty, -1, 1);
  scan(startx-1, starty-1, -1, -1);
  printf "from %d,%d ", startx, starty;
  printf "seeing %d\n", visible;

  debug=2;

  printf "%d distances, %d angles\n", length(distances), length(angles);

  totalkills=0;
  mindist=1;
  while(length(distances)) {
    printf "killing at distance %d\n", mindist;
    bestangle=9999;
    bestloc=-1;
    found=0;
    for(loc in distances) {
      if (distances[loc] > mindist) {
        if(debug>2) {
          printf " %d:%d is too far\n", loc, distances[loc];
        }
        continue;
      }
      if (angles[loc] < bestangle) {
        bestloc = loc;
        bestangle = angles[loc];
      }
      found=1;
    }
    if(found) {
      x=bestloc%width;
      y=(bestloc-x)/height;
      printf " best angle %f at %d=%d,%d\n", bestangle, bestloc,x, y;
      delete distances[bestloc];
      delete angles[bestloc];
      totalkills++;
      printf "kill %d (distance %d) is at %d,%d\n", totalkills, mindist, x, y
    } else {
      mindist++;
      printf "increasing distance to %d\n", mindist;
    }
  }

}
