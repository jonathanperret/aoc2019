BEGIN {
  g_expr = "";
  FS = "";
}

function build1(expr, sym, reg,   clause) {
  clause = "";
  if(sym == "#") {
    clause = "NOT " reg;
  } else if(sym == ".") {
    clause = reg;
  }
  if(length(clause)) {
    if(length(expr)) {
      expr = expr " || ";
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

  expr = build1(expr, $6, "D");
  expr = build1(expr, $7, "E");
  expr = build1(expr, $8, "F");
  expr = build1(expr, $9, "G");
  expr = build1(expr, $10, "H");
  expr = build1(expr, $11, "I");
  return "NOT(" expr ")";
}

function parse(     clause) {
  if($13 == "j") {
    clause = build();
    if(length(clause)) {
      if(length(g_expr)) g_expr = g_expr " || ";
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
