> /tmp/brainin.txt
tail -F /tmp/brainin.txt | ./intcode.awk -v CODE=day11.txt -v debug=0 | ./day11.awk -v startcolor=1 -v debug=0 2>&1 > /tmp/brainin.txt
