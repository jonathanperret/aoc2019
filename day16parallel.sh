LANG=C ./day16tail.awk|eval "$(for i in {1..100}; do printf './day16iter.awk|'; done; echo '|cat')"|tail -r -n 8|paste -d'\0' -s -
