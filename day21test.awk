#! /usr/bin/env LANG=C /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

BEGIN {
  g_expr = "";
  FS = "";
  glyph[0] = ".";
  glyph[1] = "#";
  cmd[0] = "w";
  cmd[1] = "j";
  cmd[2] = "z";

  g_maxdepth = 1;

  generate();
}

function _tryjumping(a,b,c,d,e,f,g,h,i, depth,    r) {
  if(!d) return 0;
  if(depth>=g_maxdepth) return 1;
  r =       tryjumping(e,f,g,h,i,1,1,1,1, depth+1) || trywalking(e,f,g,h,i,1,1,1,1, depth+1);
  r = r && (tryjumping(e,f,g,h,i,0,0,0,0, depth+1) || trywalking(e,f,g,h,i,0,0,0,0, depth+1));
  return r;
}

function _trywalking(a,b,c,d,e,f,g,h,i, depth,     r) {
  if(!a) return 0;
  if(depth>=g_maxdepth) return 1;
  r =      tryjumping(b,c,d,e,f,g,h,i,1, depth+1) || trywalking(b,c,d,e,f,g,h,i,1, depth+1);
  r = r && tryjumping(b,c,d,e,f,g,h,i,0, depth+1) || trywalking(b,c,d,e,f,g,h,i,0, depth+1);
  return r;
}

function tryjumping(a,b,c,d,e,f,g,h,i, depth,   r) {
  printf "%*s >tryjumping %*s :\n", depth,"", 15-depth, display(a,b,c,d,e,f,g,h,i);
  r = _tryjumping(a,b,c,d,e,f,g,h,i, depth);
  printf "%*s <tryjumping %*s = %d\n", depth,"", 15-depth, display(a,b,c,d,e,f,g,h,i), r;
  return r;
}

function trywalking(a,b,c,d,e,f,g,h,i, depth,   r) {
  printf "%*s >trywalking %*s :\n", depth,"", 15-depth, display(a,b,c,d,e,f,g,h,i);
  r = _trywalking(a,b,c,d,e,f,g,h,i, depth);
  printf "%*s <trywalking %*s = %d\n", depth,"", 15-depth, display(a,b,c,d,e,f,g,h,i), r;
  return r;
}

function shouldjump(a,b,c,d,e,f,g,h,i,    canjump, canwalk) {
  canjump = tryjumping(a,b,c,d,e,f,g,h,i, 0);
  canwalk = trywalking(a,b,c,d,e,f,g,h,i, 0);
  if(canjump && canwalk) {
    printf " canjump=%d, canwalk=%d: choosing to jump\n", canjump, canwalk;
    return 0;
  } else if(!(canjump || canwalk)) {
    printf " canjump=%d, canwalk=%d: inconclusive\n", canjump, canwalk;
    return 2;
  } else if(canjump) {
    printf " canjump=%d, canwalk=%d: should jump\n", canjump, canwalk;
    return 1;
  } else {
    printf " canjump=%d, canwalk=%d: should walk\n", canjump, canwalk;
    return 0;
  }
}

function display(a,b,c,d,e,f,g,h,i) {
  return sprintf("@%s%s%s%s%s%s%s%s%s", glyph[a], glyph[b], glyph[c], glyph[d], glyph[e], glyph[f], glyph[g], glyph[h], glyph[i]);
}

function generate(    a,b,c,d,e,f,g,h,i, v, formula) {
  for(a=0;a<=1;a++) {
    for(b=0;b<=1;b++) {
      for(c=0;c<=1;c++) {
        for(d=0;d<=1;d++) {
          for(e=0;e<=1;e++) {
            for(f=0;f<=1;f++) {
              for(g=0;g<=1;g++) {
                for(h=0;h<=1;h++) {
                  for(i=0;i<=1;i++) {
                    printf "evaluating %s\n", display(a,b,c,d,e,f,g,h,i);
                    v = shouldjump(a,b,c,d,e,f,g,h,i);
                    formula = !a || (d && !(b && c) && (e || h));
                    if (formula != v) printf "DISAGREEMENT\n";
                    printf "%s %s %s\n", display(a,b,c,d,e,f,g,h,i), cmd[formula], cmd[v];
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
