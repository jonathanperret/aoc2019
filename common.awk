function copyarray(src, dest,      i) {
  delete dest;
  for(i in src) {
    dest[i] = src[i];
  }
}

function savearray(array, filename,    key) {
  for(key in array) {
    printf "%s %d\n", key, array[key] > filename;
  }
  close(filename);
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

function min_i(a,    i, best, best_i) {
  best = 99999999999999999999999;
  for(i in a) {
    if(a[i] < best) {
      best = a[i];
      best_i = i;
    }
  }
  return best_i;
}

function clearscreen() {
  printf "\033[2J";
}

function showcursor() {
  printf "\033[?25h";
}

function hidecursor() {
  printf "\033[?25l";
}

function dumparray(a,      i) {
  for(i=0; i<length(a); i++) {
    printf "%d ", a[i] >> "/dev/stderr";
  }
  printf "\n" >> "/dev/stderr";
}

function dumpmatrix(matrix, xmin, xmax, ymin, ymax,     px, py) {
  for(py = ymin; py <= ymax; py++) {
    for(px = xmin; px <= xmax; px++) {
      printf "%s", matrix[px,py] >> "/dev/stderr";
    }
    printf "\n" >> "/dev/stderr";
  }
}

# silence "unused function" warnings
0 {
  dumparray();
  min_i();
  copyarray();
  gcd();
  lcm();
  clearscreen();
  showcursor();
  hidecursor();
  dumpmatrix();
}
