./day23.awk -v debug=0 2>&1|awk -F, '/NAT sending/ {if($2!=last) { last=$2; print $2 } else exit 0}'
