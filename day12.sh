#!/bin/bash

export LANG=C

time (
  for i in {1..3}; do ./day12axis.awk -v axis=$i -v maxsteps=1000000  < day12.txt & done; wait
) | ./day12.awk
