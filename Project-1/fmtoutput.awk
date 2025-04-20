{ 
	throughput=num_ops/$1;
	perf=throughput/base_throughput;
	print "|hash-0" cmd_ver "|" opti "|" $1 "|" $3 "|" $5 "|" $7 "|" throughput "|" perf "|"; 
}
