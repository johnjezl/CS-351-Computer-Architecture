#! /bin/bash

NUM_RUNS=10

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
		NUM_RUNS_PER_PROGRAM=$NUM_RUNS
		if [[ "$VERSION" -eq 0 ]]; then
			NUM_RUNS_PER_PROGRAM=1
		fi
		
		REAL_TOTAL=0.0
		USER_TOTAL=0.0
		SYS_TOTAL=0.0
		MEM_TOTAL=0
		for RUN in $(seq 1 "$NUM_RUNS_PER_PROGRAM"); do

			# Gather timing output for post-processing
			CMD='/usr/bin/time -f "%e real\t%U user\t%S sys\t%M memory (KB)" ./hash-0'$VERSION
			echo "Run #${RUN}: " $CMD
			OUTPUT=`/usr/bin/time -f "%e real\t%U user\t%S sys\t%M memory (KB)" ./hash-0${VERSION} 2>&1`
			echo $OUTPUT

			REAL_TIME=`echo ${OUTPUT} | cut -f1 -d" "`
			USER_TIME=`echo ${OUTPUT} | cut -f3 -d" "`
			SYS_TIME=`echo ${OUTPUT} | cut -f5 -d" "`
			MEM_USED=`echo ${OUTPUT} | cut -f7 -d" "`
			REAL_TOTAL=$(printf '%s + %s\n' "$REAL_TOTAL" "$REAL_TIME" | bc -l)
			USER_TOTAL=$(printf '%s + %s\n' "$USER_TOTAL" "$USER_TIME" | bc -l)
			SYS_TOTAL=$(printf '%s + %s\n' "$SYS_TOTAL" "$SYS_TIME" | bc -l)
			MEM_TOTAL=$(printf '%s + %s\n' "$MEM_TOTAL" "$MEM_USED" | bc -l)
		done

		echo $REAL_TOTAL real $USER_TOTAL user $SYS_TOTAL sys $MEM_TOTAL mem

		REAL_AVE=$(printf '%s / %s\n' "$REAL_TOTAL" "$NUM_RUNS_PER_PROGRAM" | bc -l)
		USER_AVE=$(printf '%s / %s\n' "$USER_TOTAL" "$NUM_RUNS_PER_PROGRAM" | bc -l)
		SYS_AVE=$(printf '%s / %s\n' "$SYS_TOTAL" "$NUM_RUNS_PER_PROGRAM" | bc -l)
		MEM_AVE=$(printf '%s / %s\n' "$MEM_TOTAL" "$NUM_RUNS_PER_PROGRAM" | bc -l)
			
		VALUES=`echo $REAL_AVE real $USER_AVE user $SYS_AVE sys $MEM_AVE mem`
		echo $VALUES

		# How many hashes were calculated?
		NUM_OPS=`wc -l ./hash-0${VERSION}.txt | cut -f1 -d" "`
		echo "NUM_OPS=$NUM_OPS"
	
		if [[ "$VERSION" -eq 0 ]]; then
			BASE_THROUGHPUT=$(printf '%s / %s\n' "$NUM_OPS" "$REAL_AVE" | bc -l)
			echo Base Throughput = $BASE_THROUGHPUT
		fi

		THROUGHPUT=$(printf '%s / %s\n' "$NUM_OPS" "$REAL_AVE" | bc -l)
		PERF=$(printf '%s / %s\n' "$THROUGHPUT" "$BASE_THROUGHPUT" | bc -l)
		printf "|hash-0%1d|%s|%0.2f|%0.2f|%0.2f|%0.0f|%0.0f|%0.2f|\n" $VERSION "$OPTIMIZATION" $REAL_AVE $USER_AVE $SYS_AVE $MEM_AVE $THROUGHPUT $PERF >> $RESULTS_FILE
	done
	make rmtargets
done

