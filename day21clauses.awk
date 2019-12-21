BEGIN {
  expr = "";
  FS = "";
}

function build1(sym, reg) {
  return (sym == "#") ? reg : ("NOT " reg);
}

function build() {
  return build1($2, "A") " " build1($3, "B") " " build1($4, "C") " " build1($5, "D");
}

{
  if($8 == "j") {
    if(length(expr)) expr=expr "||";
    expr = expr "(" build() ")";
  }
}

END {
  print expr;
}
