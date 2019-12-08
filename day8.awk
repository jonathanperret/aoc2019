#!/usr/bin/awk -f

BEGIN {FS="";layerlength=25*6;min0=999999999999;}

{for(i=1;i<=NF;i++){ pixel=$i; stats[$i]++;   if(i%layerlength == 0) { if(stats[0]<min0){ min0=stats[0];result=stats[1]*stats[2]}  delete stats; layer++ } }}

END {print result}
