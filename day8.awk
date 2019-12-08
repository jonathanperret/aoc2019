#!/usr/bin/awk -f

BEGIN {
  FS="";
  imagewidth=ENVIRON["IMAGEWIDTH"];
  imageheight=ENVIRON["IMAGEHEIGHT"];
  layerlength=imagewidth * imageheight;
  glyphs[1] = "  ";
  glyphs[0] = "██";
  glyphs[2] = "░░";
}

function showimage() {
  for(y=0;y<imageheight;y++) {
    for(x=0;x<imagewidth;x++) {
      printf "%s", glyphs[composite[y*imagewidth+x]] >> "/dev/stderr";
    }
    printf "\n" >> "/dev/stderr";
  }
}

function sendpbmto(cmd) {
  printf "P1\n%d %d\n", imagewidth, imageheight | cmd;
  for(i=0;i<imageheight*imagewidth;i++) {
    printf "%d ", composite[i] | cmd;
  }
}

{
  layeroffset = 0;
  for(i=0;i<layerlength;i++) {
    composite[i]=2;
  }
  for(i=1;i<=NF;i++){
    pixel=$i;

    if (pixel < 2 && composite[layeroffset] >= 2) {
      composite[layeroffset] = pixel;
    }

    layeroffset++;

    if(layeroffset == layerlength) {
      layer++;
      layeroffset = 0;
      if (debug) {
        showimage();
        print "----------" >> "/dev/stderr";
      }
    }
  }
  sendpbmto("convert -bordercolor white -border 1 - -|tesseract --psm 13 --dpi 70 stdin stdout|head -1");
  exit
}
