BEGIN {
  FS=")";
}

{
  orbitee=$1;
  orbiter=$2;
  orbits[orbiter] = orbitee;
}

END {
  youdistance[orbits["YOU"]] = 1;
  while(!youdistance["SAN"]) {
    printf "iteration %d\n", iter++;
    for(orbiter in orbits) {
      orbitee = orbits[orbiter];
      if(youdistance[orbiter] && !youdistance[orbitee]) {
        youdistance[orbitee] = youdistance[orbiter] + 1;
        printf "> [%s]=%d\n", orbitee, youdistance[orbitee];
      } else if(!youdistance[orbiter] && youdistance[orbitee]) {
        youdistance[orbiter] = youdistance[orbitee] + 1;
        printf "< [%s]=%d\n", orbiter, youdistance[orbiter];
      }
    }
  }
  print youdistance["SAN"] - 2;
}
