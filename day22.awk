#! /usr/bin/env LANG=C /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

@include "common"

BEGIN {
  printf "" >> "/dev/stderr";
  g_decksize = 1;
  g_watchedcard = -1;
  g_watchedcardpos = -1;
  g_formula = "n";
  g_offset = 0;
  g_factor = 1;
  g_watchedpos = 2020;

  if(0) testModInverse();

}

function testModInverse(      a, m, mi) {
  m = 11;
  mi = -1;
  for(a=-2*m+1; a < 2*m; a++) {
    mi = modInverse(a, m);
    if(mi>0)
      printf "mi(%2d, %d) = %2g   (%2d * %g) mod %d = %d\n", a, m, mi, a, mi, m, norm((a*mi)%m, m);
  }
  exit(0);
}

function show(      i) {
  printf "> %s\n", $0;
  if(g_watchedcard >= 0) {
    printf "formula is now %s\n", g_formula;
    printf "formula is also %d + %d * n : gives %d\n", g_offset, g_factor, normalize(g_offset + g_factor * g_watchedcard);
    printf "watched card %d is at position %d\n", g_watchedcard, g_watchedcardpos;

    # pos = o + f * n
    # pos - o = f * n
    # n = (pos - o) / f
    printf "pos - offset = %d\n", g_watchedpos - g_offset;
    printf "watched position %d has card %d\n", g_watchedpos, cardat(g_watchedpos);
    printf "deck starts with";
    for(i=0; i<10; i++) {
      printf " %d", cardat(i);
    }
    printf "\n";
  }
}

function cardat(pos,     mi) {
  #printf "[dividing %d by %d]\n", (pos - g_offset), g_factor;
  mi = modInverse(g_factor, g_decksize);
  #printf "[modInverse of %d is %d]\n", g_factor, mi;
  return normalize((pos - g_offset) * mi);
}

/take [0-9]+ cards/ {
  g_decksize = 0 + $2;
  printf "deck size is %d\n", g_decksize;
}

/watch card [0-9]+/ {
  g_watchedcard = 0 + $3;
  g_watchedcardpos = g_watchedcard;
}

function norm(a, m) {
  if (a < 0) {
    # printf "%d ->", a;
    a = m - ((-a) % m);
    # printf "%d\n", a;
  }
  return a % m;
}

function modInverse(a, m,    xa, ya, g)
{
  a = norm(a, m);
  g = gcdExtended(a, m, xa, ya);
  if (g != 1) {
    printf "no inverse for %d mod %d (gcd=%d)\n", a, m, g;
    return -1;
  }
  else {
    return norm(xa[0], m);
  }
}

function  gcdExtended(a, b, xa, ya,       g, x1a, y1a)
{
  delete xa;
  delete ya;

  if (a == 0) {
    xa[0] = 0; ya[0] = 1;
    return b;
  }

  g = gcdExtended(b%a, a, x1a, y1a);

  xa[0] = y1a[0] - int(b/a) * x1a[0];
  ya[0] = x1a[0];

  return g;
}

function normalize(pos) {
  # printf "[normalize(%d)]", pos;
  return norm(pos, g_decksize);
}

function mul(n,    oppos) {
  g_watchedcardpos = normalize(g_watchedcardpos * n);
  if(index(g_formula "*", "*") > index(g_formula "+", "+")) {
    g_formula = n " * (" g_formula ")";
  } else {
    oppos = index(g_formula, "*");
    if (oppos > 0) {
      g_formula = (substr(g_formula, 1, oppos - 1) * n) "" substr(g_formula, oppos - 1, length(g_formula) - oppos + 2);
    } else {
      g_formula = n " * " g_formula;
    }
  }

  g_offset = normalize(g_offset * n);
  g_factor = normalize(g_factor * n);
}

function add(n) {
  g_watchedcardpos = normalize(g_watchedcardpos + n);
  if(index(g_formula "*", "*") < index(g_formula "+", "+")) {
    g_formula = "(" g_formula ")";
  }
  g_formula = n " + " g_formula;
  g_offset = normalize(g_offset + n);
}

function pow(n,     p, raised_o, raised_f, tmp_o, tmp_f, final_o, final_f) {
  # pos = o + f * n
  # pos' = o + f * pos
  # pos' = o + f * (o + f * n)
  # pos' = o + f * o + f * f *n
  # pos'' = o + f * (o + f * o + f * f *n)
  # pos'' = (o + f * o + f * f * o) + (f * f * f * n)
  # pos'' = o + f * o + f * f * o + f * f * f * n
  # pos'' = o + fo + ffo + fffn

  # fn^7 = fn^4 . fn^2 . fn
  p = 1;
  final_f = 1;
  final_o = 0;
  raised_f = g_factor;
  raised_o = g_offset;
  while(n>0) {
    printf "p=%d o=%d f=%d\n", p, raised_o, raised_f;
    if(n % 2 == 1) {
      final_o = normalize(raised_o + raised_f * final_o);
      final_f = normalize(raised_f * final_f);
    }
    n = int(n/2);
    raised_o = normalize(raised_o + raised_f * raised_o);
    raised_f = normalize(raised_f * raised_f);
    p++;
  }

  g_offset = final_o;
  g_factor = final_f;
}

/deal into new stack/ {
  mul(-1);
  add(-1);
}

/deal with increment [0-9]+/ {
  mul($4);
}

/cut [0-9-]+/ {
  add(-$2);
}

/repeat [0-9]+ times/ {
  pow($2);
}

{
  show();
}

END {
  close("/dev/stderr");

  exit 0;
  if(0) {
  }
}
