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
  distance = 0;
  while(start in orbits) {
    chain[start] = distance++;
    start = orbits[start];
  }
  target=orbits["SAN"];
  distance = 0;
  while(target in orbits) {
    if(target in chain) {
      print chain[target] + distance;
      exit;
    }
    distance++;
    target = orbits[target];
  }
}
