#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=invalid --bignum -f

BEGIN {
  FS=" ";
  step=0;
  debug=strtonum("DEBUG" in ENVIRON ? ENVIRON["DEBUG"] : "0");
  delete states;
  period=0;
}

{
  gsub("[<>xyz=]", "", $0);
  pos[NR-1] = strtonum($axis);
  vel[NR-1] = 0;
}

function dumpmoon() {
  printf "After %d steps:\n", step >> "/dev/stderr";
  for(moon=0; moon<nmoons; moon++) {
    printf "pos=%d, vel=%d\n", pos[moon], vel[moon] >> "/dev/stderr";
  }
  printf "\n" >> "/dev/stderr";
}

function applygravity(m1, m2) {
  if(pos[m1] == pos[m2]) return;
  if(pos[m1] < pos[m2]) {
    #printf "pulling %d to %d (<)\n", m1, m2 >> "/dev/stderr";
    vel[m1]++; vel[m2]--;
  } else {
    #printf "pulling %d to %d (>)\n", m1, m2 >> "/dev/stderr";
    vel[m1]--; vel[m2]++;
  }
}

function applyvelocity(m) {
  pos[m] += vel[m];
}

function checkstate() {
  h = "";
  for(moon=0; moon<nmoons; moon++) {
    h = h sprintf("pos=%d, vel=%d | ", pos[moon], vel[moon]);
  }
  if(debug) printf "state=%s\n", h >> "/dev/stderr";
  if (h in states) {
    printf "repeated after %d steps\n", step >> "/dev/stderr";
    period = step;
  }
  states[h] = step;
}

function simulate() {
  for(moon=0; moon<nmoons; moon++) {
    for(moon2=moon+1; moon2<nmoons; moon2++) {
      applygravity(moon, moon2);
    }
  }
  for(moon=0; moon<nmoons; moon++) {
    applyvelocity(moon);
  }
  checkstate();
}

END {
  nmoons = length(pos);
  for(step=0; step<maxsteps && !period; step++) {
    if (debug) dumpmoon();
    simulate();
  }
  dumpmoon();

  if(period) {
    printf "%d %d\n", axis, period;
  }
  close("/dev/stderr");
}
