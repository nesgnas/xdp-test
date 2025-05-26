set datafile separator ","
set xdata time
set timefmt "%s"
set format x "%H:%M:%S"
set terminal dumb size 120,30   # vẽ ngay terminal (ascii art)
set title "CPU Usage over Time"
set xlabel "Time"
set ylabel "CPU (%)"
plot "cpu_usage.csv" using 1:2 with lines title "CPU %"

