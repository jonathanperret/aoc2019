#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

BEGIN {
  ENVIRON["LANG"] = "C";
  width = 0; height = 0;
  x = 0; y = 0;
}

# function copyarray(src, dest,      i) {
#   delete dest;
#   for(i in src) {
#     dest[i] = src[i];
#   }
# }
# 
# function abs(_x) {
#   return _x < 0 ? -_x : _x;
# }

function parse(      ) {
  if($1 == 10) {
    if(x>0) { width = x; height = y+1; }
    x = 0; y++;
  } else {
    if ($1 == 35) {
      space[x,y] = "#";
    } else if ($1 == 46) {
      space[x,y] = ".";
    } else if ($1 == 94) {
      space[x,y] = "#";
    }
    x++;
  }
}

{
  parse();
}

function find_intersections() {
  sum = 0;
  for(y = 0; y < height; y++) {
    for(x = 0; x < width; x++) {
      if(space[x,y] == "#" && space[x+1,y] == "#" && space[x-1,y] == "#" && space[x,y-1] == "#" && space[x,y+1] == "#") {
        sum ++;
      }
    }
  }
  print sum;
}

END {
  print width, height;
  find_intersections();
  # close("/dev/stderr");
}

