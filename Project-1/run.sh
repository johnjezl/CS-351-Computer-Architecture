#! /bin/bash

RESULTS_FILE=./results.out

# These are the sets of optimization parameter we're going to try
OPTIMIZATIONS=("" 
	"-O2" 
	"-O3" 
	"-Ofast" 
	"-O3 -march=native -mtune=native" 
	"-O3 -funroll-loops -fomit-frame-pointer -flto" 
	"-O3 -march=native -mtune=native -funroll-loops -fomit-frame-pointer -flto" 
	"-O3 -march=native -mtune=native -funroll-loops -fomit-frame-pointer -flto -DNDEBUG"
	"-Ofast -march=native -mtune=native -funroll-loops -fomit-frame-pointer -flto -DNDEBUG")

# Write table header to results file (and initialize file)
echo "| program name | optimization level | real (wall‑clock) time | user time | system time | memory usage | throughput | performance improvement over base program |
|--------------|--------------------|------------------------|-----------|-------------|--------------|------------|------------------------------------------|" > $RESULTS_FILE

# Cleanup any old binaries
make rmtargets

for OPTIMIZATION in "${OPTIMIZATIONS[@]}"; do
	echo "Optimizations: " $OPTIMIZATION

	# Build new binaries with the current optimizations
	echo 'make OPT="$OPTIMIZATION"'
	make OPT="$OPTIMIZATION"

	BASE_THROUGHPUT=0
	
	# For each version of the program, gather metrics and output to results file
	for VERSION in {0..5}; do
		
		# Gather timing output for post-processing
		CMD='/usr/bin/time -f "%e real\t%U user\t%S sys\t%M memory (KB)" ./hash-0'$VERSION
		echo $CMD
		OUTPUT=`/usr/bin/time -f "%e real\t%U user\t%S sys\t%M memory (KB)" ./hash-0${VERSION} 2>&1`
		echo $OUTPUT
		
		# How many hashes were calculated?
		NUM_OPS=`wc -l ./hash-0${VERSION}.txt | cut -f1 -d" "`

		if [[ "$VERSION" -eq 0 ]]; then
			BASE_THROUGHPUT=`echo $OUTPUT | awk -v num_ops="$NUM_OPS" '{ throughput=num_ops/$3; print throughput; }'`
			echo Base Throughput = $BASE_THROUGHPUT
		fi

		echo $OUTPUT |  awk -v cmd_ver="$VERSION" -v opti="$OPTIMIZATION" -v num_ops="$NUM_OPS" -v base_throughput="$BASE_THROUGHPUT " -f ./fmtoutput.awk >> $RESULTS_FILE
	done
	make rmtargets
done

