#!/usr/bin/awk -f

BEGIN {
  FS="";
  imagewidth=ENVIRON["IMAGEWIDTH"];
  imageheight=ENVIRON["IMAGEHEIGHT"];
  layerlength=imagewidth * imageheight;
  glyphs[0] = " ";
  glyphs[1] = "█";
  glyphs[2] = "░";
}

function showimage() {
  for(y=0;y<imageheight;y++) {
    for(x=0;x<imagewidth;x++) {
      printf "%s", glyphs[composite[y*imagewidth+x]];
    }
    printf "\n";
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
      showimage();
      print "----------";
    }
  }
  showimage();
  exit
}
