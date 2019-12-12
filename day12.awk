#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=invalid --bignum -f

BEGIN {
  FS=" ";
  debug=strtonum("DEBUG" in ENVIRON ? ENVIRON["DEBUG"] : "0");
  delete periods;
}

{
  periods[$1] = $2;
  printf "Got period for axis %d: %d\n", $1, $2 > "/dev/stderr";
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

END {
  if(length(periods) == 3) {
    printf "Found all periods! %d %d %d\n", periods[1], periods[2], periods[3];
    printf "Global period: %d\n", lcm(lcm(periods[1], periods[2]), periods[3]);
  }
  close("/dev/stderr");
}
