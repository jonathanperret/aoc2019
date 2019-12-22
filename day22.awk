#! /usr/bin/env LANG=C /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=no-ext --bignum -f

@include "common"

BEGIN {
  printf "" >> "/dev/stderr";
  g_decksize = 1;
  g_watchedcard = 0;
}

function show() {
  printf "> %s\n", $0;
  printf "watched card is at position %d\n", g_watchedcard;
}

/take [0-9]+ cards/ {
  g_decksize = 0 + $2;
  printf "deck size is %d\n", g_decksize;
}

/watch card [0-9]+/ {
  g_watchedcard = 0 + $3;
}

function normalize(pos) {
  return (pos + g_decksize) % g_decksize;
}

/deal into new stack/ {
  g_watchedcard = normalize(g_watchedcard * -1);
  g_watchedcard = normalize(g_watchedcard - 1);
}

/deal with increment [0-9]+/ {
  g_watchedcard = normalize(g_watchedcard * $4);
}

/cut [0-9-]+/ {
  g_watchedcard = normalize(g_watchedcard - $2);
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
