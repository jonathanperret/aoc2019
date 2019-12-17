#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

BEGIN {
  ENVIRON["LANG"] = "C";
  sum = 0;
}

{
  sum = (sum + $1) % 10;
  print sum;
}
