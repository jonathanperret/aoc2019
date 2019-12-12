#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=invalid -f

BEGIN {
  FS=" ";
  step=0;
  if(!debug) debug=0;
}

{
  gsub("[<>xyz=]", "", $0);
  xpos[NR-1] = strtonum($1);
  ypos[NR-1] = strtonum($2);
  zpos[NR-1] = strtonum($3);
  xvel[NR-1] = 0;
  yvel[NR-1] = 0;
  zvel[NR-1] = 0;
}

function dumpmoons() {
  if(debug) {
    printf "After %d steps:\n", step;
    for(moon=0; moon<nmoons; moon++) {
      printf "pos=<x=%2d, y=%2d, z=%2d>, vel=<x=%2d, y=%2d, z=%2d>\n", xpos[moon], ypos[moon], zpos[moon], xvel[moon], yvel[moon], zvel[moon];
    }
    printf "\n";
  }
}

function applygravity(pos, vel, m1, m2) {
  if(pos[m1] == pos[m2]) return;
  if(pos[m1] < pos[m2]) {
    #printf "pulling %d to %d (<)\n", m1, m2;
    vel[m1]++; vel[m2]--;
  } else {
    #printf "pulling %d to %d (>)\n", m1, m2;
    vel[m1]--; vel[m2]++;
  }
}

function applyvelocity(pos, vel, m) {
  pos[m] += vel[m];
}

function abs(v) {return v < 0 ? -v : v}

function dumpenergy() {
  printf "Energy after %d steps:\n", step;
  totalsum = 0;
  totalmsg = "";
  for(moon=0; moon<nmoons; moon++) {
    pot = abs(xpos[moon]) + abs(ypos[moon]) + abs(zpos[moon]);
    printf "pot: %d + %d + %d = %2d;   ", abs(xpos[moon]), abs(ypos[moon]), abs(zpos[moon]), pot;
    kin = abs(xvel[moon]) + abs(yvel[moon]) + abs(zvel[moon]);
    printf "kin: %d + %d + %d = %d;   ", abs(xvel[moon]), abs(yvel[moon]), abs(zvel[moon]), kin;
    total = pot * kin;
    printf "total: %2d * %d = %d", pot, kin, total;
    printf "\n";
    totalsum += total;
    totalmsg = totalmsg total " + ";
  }
  printf "Sum of total energy: %s = %d", substr(totalmsg, 1, length(totalmsg) - 3), totalsum;
}

function checkstate(pos, vel, states, axis) {
  if (axis in period) return;
  h = "";
  for(moon=0; moon<nmoons; moon++) {
    h = h sprintf("pos=%d, vel=%d | ", pos[moon], vel[moon]);
  }
  if(debug) printf "%s state=%s\n", axis, h;
  if (h in states) {
    printf "%s repeated after %d steps\n", axis, step;
    period[axis] = step;
  }
  states[h] = 1;
}

function gcd(m, n,    t) {
  # Euclid's method
  while (n != 0) {
    t = m
    m = n
    n = t % n
  }
  return m
}

function lcm(m, n,    r) {
  if (m == 0 || n == 0)
    return 0
  r = m * n / gcd(m, n)
  return r < 0 ? -r : r
}

function simulate() {
  for(moon=0; moon<nmoons; moon++) {
    for(moon2=moon+1; moon2<nmoons; moon2++) {
      applygravity(xpos, xvel, moon, moon2);
      applygravity(ypos, yvel, moon, moon2);
      applygravity(zpos, zvel, moon, moon2);
    }
  }
  for(moon=0; moon<nmoons; moon++) {
    applyvelocity(xpos, xvel, moon);
    applyvelocity(ypos, yvel, moon);
    applyvelocity(zpos, zvel, moon);
  }
  checkstate(xpos, xvel, xstates, "x");
  checkstate(ypos, yvel, ystates, "y");
  checkstate(zpos, zvel, zstates, "z");
  printf "%d got %d periods\n", step, length(period);
  if(length(period) == 3) {
    printf "Found all periods!\n";
    printf "Global period: %d\n", lcm(period["x"], period["y"], period["z"]);
    exit(0);
  }
}

END {
  nmoons = length(xpos);
  for(step=0; step<maxsteps; step++) {
    dumpmoons();
    simulate();
  }
  dumpmoons();

  dumpenergy();
}
