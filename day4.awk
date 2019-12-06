function checkpass(pass) {
  split(pass, chars, "");
  longest = 1;
  last = "";
  currentlength = 1;
  hasdouble = 0;
  decreases = 0;
  for(i=1; i<=length(pass); i++) {
    if(chars[i] == last) {
      currentlength++;
    } else {
      if (currentlength == 2) {
        hasdouble = 1;
      }
      if (currentlength > longest) {
        longest = currentlength;
      }
      currentlength = 1;
    }
    if(i < length(pass) && chars[i] > chars[i+1]) {
      decreases++;
    }
    last = chars[i];
  }
  if (currentlength == 2) {
    hasdouble = 1;
  }
  # printf "%s longest=%d hasdouble=%d decreases=%d\n", pass, longest, hasdouble, decreases;
  return (hasdouble && decreases == 0);
}

BEGIN {
  FS = "-";
}

{
  min = int($1);
  max = int($2);

  for(n=min; n<=max; n++) {
    result = checkpass(n);
    print n, result
  }
}
