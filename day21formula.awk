#! /usr/bin/env LANG=C /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

BEGIN {
  print formula();
}

function live(a, b, c, d,   expr) {
  if (!length(d)) {
    return "(" live(a, b, c, "false") " AND " live(a, b, c, "true") ")";
  }
  if (a == "false" && d == "false") return "false";
  if (!length(c)) {
    return "(" live(a, b, "false", "") " AND " live(a, b, "true", "") ")";
  }
  if (!length(b)) {
    return "(" live(a, "false", "", "") " AND " live(a, "true", "", "") ")";
  }
  expr = "(" canwalk(a, b, c, d) " OR " canjump(a, b, c, d) ")";
  printf "live? %s %s %s %s = %s\n", a, b, c, d, expr >> "/dev/stderr";
  return expr;
}

function canjump(a, b, c, d,   expr) {
  if (d == "false") {
    expr = "false";
  } else {
    expr = d;
  }

  printf "canjump? %s %s %s %s = %s\n", a, b, c, d, expr >> "/dev/stderr";
  return expr;
}

function canwalk(a, b, c, d,   expr) {
  if (a == "false") { return "false"; }
  expr = "(" a " AND " live(b, c, d, "") ")";
  printf "canwalk? %s %s %s %s = %s\n", a, b, c, d, expr >> "/dev/stderr";
  return expr;
}

function formula() {
  return "NOT " canwalk("A", "B", "C", "D");
}
