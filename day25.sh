> out.txt; for seq in {drop,#}\ pointer:{drop,#}\ coin:{drop,#}\ mug:{drop,#}\ manifold:{drop,#}\ hypercube:{drop,#}\ easter\ egg:{drop,#}\ astrolabe:{drop,#}\ candy\ cane:east:; do echo "$seq";(cat day25cmds.txt; echo "$seq"|awk -v RS=: '/../{printf $0"\n"}') | grep -v '#'|od -t u1|awk '{for(i=2;i<=NF;i++) print $i; fflush()}' | ./intcode.awk -v ctscode=0 -v debug=0 -v CODE=day25.txt | gawk '{printf("%c", $1+0);fflush()}'|tee -a out.txt|tail; done