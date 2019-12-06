function checkpass(pass) {
  split(pass, chars, "");
  doubles = 0;
  decreases = 0;
  for(i=1; i<length(pass); i++) {
    if(chars[i] == chars[i+1]) {
      doubles++;
    }
    if(chars[i] > chars[i+1]) {
      decreases++;
    }
  }
  return (doubles > 0 && decreases == 0);
}

BEGIN {
  FS = "-";
}

{
  min = int($1);
  max = int($2);

  for(n=min; n<=max; n++) {
    print n, checkpass(n)
  }
}
