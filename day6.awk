BEGIN {
  FS=")";
}

{
  orbitee=$1;
  orbiter=$2;
  orbits[orbiter] = orbitee;
}

END {
  printf "%d orbits\n", length(orbits);
  for(orbiter in orbits) {
    printf "[%s][%s]\n", orbiter, orbits[orbiter];
    tmp = orbiter;
    while(tmp in orbits) {
      total++;
      print total, orbiter, tmp;
      tmp = orbits[tmp];
      print tmp;
    }
  }
  print total;
}
