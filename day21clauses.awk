#! /usr/bin/env LANG=C /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

BEGIN {
  g_expr = "";
  FS = "";
}

function build1(expr, sym, reg,   clause) {
  clause = "";
  if(sym == "#") {
    clause = "!" reg;
  } else if(sym == ".") {
    clause = reg;
  }
  if(length(clause)) {
    if(length(expr)) {
      expr = expr "+";
    }
    expr = expr clause;
  }
  return expr;
}

function build(     expr) {
  expr = "";
  expr = build1(expr, $2, "A");
  expr = build1(expr, $3, "B");
  expr = build1(expr, $4, "C");

  expr = build1(expr, $5, "D");
  expr = build1(expr, $6, "E");
  expr = build1(expr, $7, "F");
  expr = build1(expr, $8, "G");
  expr = build1(expr, $9, "H");
  expr = build1(expr, $10, "I");
  return "!(" expr ")";
}

function parse(     clause) {
  if($12 == "j") {
    clause = build();
    if(length(clause)) {
      if(length(g_expr)) g_expr = g_expr "+";
      g_expr = g_expr "(" clause ")";
    }
  }
}

/^@/ {
  parse();
}

END {
  print g_expr;
}
