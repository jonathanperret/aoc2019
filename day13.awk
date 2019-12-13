#! /usr/local/Cellar/gawk/5.0.1/libexec/gnubin/awk --lint=invalid --bignum -f

BEGIN {
  ENVIRON["LANG"] = "C";
  clearscreen();
  hidecursor();
  glyphs[0] = "  ";
  glyphs[1] = "██";
  glyphs[2] = "░░";
  glyphs[3] = "——";
  glyphs[4] = "◐◑";
  paddlex=0;
  ballx=0;
  print "-------------" >> "/dev/stderr";
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

/^CTS$/ {
  if(ballx > paddlex) {
    print "1" >> "/tmp/joystick.txt";
    print "going right" >> "/dev/stderr";
  } else if(ballx < paddlex) {
    print "-1" >> "/tmp/joystick.txt";
    print "going left" >> "/dev/stderr";
  } else {
    print "0" >> "/tmp/joystick.txt";
    print "staying" >> "/dev/stderr";
  }
  fflush("/tmp/joystick.txt");
  # system("sleep 0.1");
  NR--; next;
}

NR%3==1{tilex=$1}

NR%3==2{tiley=$1}

NR%3==0{
  tileblock=$1;
  # print tiley,tilex,tileblock;
  if(tilex < 0) {
    printf "\033[%d;%df%s", 1, 1, "         ";
    printf "\033[%d;%df%s", 1, 1, tileblock;
    printf "score %d\n", tileblock >> "/dev/stderr";
  } else {
    if (tileblock == 3) {
      paddlex = tilex;
      printf "paddle %d\n", paddlex >> "/dev/stderr";
    } else if (tileblock == 4) {
      ballx = tilex;
      printf "ball %d %d\n", tilex, tiley >> "/dev/stderr";
    }
    printf "\033[%d;%df%s", tiley+2,2*tilex+1,glyphs[tileblock];
  }
  fflush();
}

END {
  close("/dev/stderr");
  close("/tmp/joystick.txt");
  showcursor();
}
