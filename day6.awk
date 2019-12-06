BEGIN {
  FS=")";
}

{
  orbitee=$1;
  orbiter=$2;
  orbits[orbiter] = orbitee;
}

END {
  start=orbits["YOU"];
  target=orbits["SAN"];
  youdistance[start] = 0;
  while(!(target in youdistance)) {
    printf "iteration %d\n", iter++;
    for(orbiter in orbits) {
      orbitee = orbits[orbiter];
      if((orbiter in youdistance) && !(orbitee in youdistance)) {
        youdistance[orbitee] = youdistance[orbiter] + 1;
        printf "< [%s]=%d\n", orbitee, youdistance[orbitee];
      } else if((orbitee in youdistance) && !(orbiter in youdistance)) {
        youdistance[orbiter] = youdistance[orbitee] + 1;
        printf "> [%s]=%d\n", orbiter, youdistance[orbiter];
      }
    }
  }
  print youdistance[target];
}
