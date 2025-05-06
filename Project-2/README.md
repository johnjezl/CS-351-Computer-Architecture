# Project 2

## Description
This project explores increasing performance by increasing parallelism of execution. In this case, using threading.  The hashing algorithm `hash-04` from Project 1 is parallelized to different degrees (i.e. the number of simultaneous threads are varied) to see how far threading can be productively taken. 


## Process
Similar to Project 1, the hashing program is run using the `time` utility to collect runtime information. Unlike Project 1, a thread count is specified over which the hashing load is distributed. `hash04` is executed multiple times, with the number of threads being increased for each run. This allows us to see at what point the performance benefit drops off and/or regresses.


## Results

### Raw Timing Data

|Thread<br>Count|Wall Clock<br>Time|User Time|System Time|Speedup|
|:--:|--:|--:|--:|:--:|
|1|19.06|13.99| 2.15|1.00|
|2| 7.88|14.65| 0.50| 2.42|
|3| 5.41|14.75| 0.56| 3.52|
|4| 4.33|14.98| 0.73| 4.40|
|5| 3.73|15.89| 0.85| 5.11|
|6| 3.39|15.74| 1.01| 5.62|
|7| 2.88|16.04| 0.99| 6.62|
|8| 2.63|16.08| 1.19| 7.25|
|16| 1.90|17.58| 2.88|10.03|
|24| 1.85|18.28| 7.10|10.30|
|32| 1.81|18.00|14.57|10.53|
|40| 1.85|17.55|21.49|10.30|
|48| 1.82|17.38|30.51|10.47|
|56| 1.83|17.18|37.66|10.42|
|64| 1.82|16.81|36.61|10.47|
|72| 1.87|16.92|37.58|10.19|
|80| 1.88|16.98|34.50|10.14|


### Speed-Up vs Thread Count

![Results Graph](./"Speedup vs Thread Count.png")

### Evaluation

#### Question: Why you think more threads aren’t necessary better?

The system used to run these tests has a CPU with 18 cores.  As the number of threads approaches that number, there becomes more competition for access to those cores, and as it reaches that number, the CPU is not able to process more threads concurrently, resulting in threads having to wait their turn.  In the aggregate, the program still gets roughly the same amount compute resources, so the total runtime doesn't vary considerably from one case to the next.
  

## Exploring Amdahl's Law

Amdahl's Law suggest that the formula for representing the serial vs parallel time a program runs is represented by the equation:

$T = sT + pT$ 

Which further factors to:

$T = (1 - p)T + pT$

And when we add N thread to the equation we get:


$T = (1 - p)T + \frac{p}{n}T$

Or:

$\textrm{speed-up factor} = \frac{1}{(1 - p) + \frac{p}{n}}$

### Question: Do you think it’s possible to get “perfect scaling” — meaning that the (1-p) terms is zero?

Not likely. Virtually all algorithms and problems to be solved involve a mix of operations, some of which will be parallelizable and some which won't.  In addition, there will always be setup, teardown, and, more importantly, handling of the resulting data, which will often be less parallelizable than the computations needed to generate the solution.  In the context of the algorithm at hand, setup includes opening and mapping the input time into memory.  There is also the synchronization enforced by the `barrier` (i.e. `arrive_and_wait()`).  And on top of all that, like a big ole juicy meatball on top of a delicious plate of shaghetti, is the limitations of reducing the size of the threads' tasks below the level of an "atomic" parallelizable operation. In this case, that would probably be the computation of a single hash.

### Amdahl's Law Results

#### Base Run

After modifying `hash-04` to add timing instrumentation, running the program with a single thread will allow us to compute the percentage of the program's runtime that is parallelizable.

```
jjezl@blue:~/projects/CS351/CS-351-Computer-Architecture/Project-2$ timed 1
main program 0.0115406 s
results output 1.189e-06 s
main program 14.869432787 s
```

$\textrm{serial} = \frac{0.0115 + 0.00000118}{14.457} = 0.000796\ (or\ 0.0796\\%)$

This shows us that since the serial portion of the program is `0.0796%` of the program's runtime, then `1 - 0.000796 = 0.999204` or `99.920%` of the program is parallalizable.

Based on Amdahl's Law, this means the predicted speed-up for 2 threads would be:

$\textrm{speed-up} = \frac{1}{1 - 0.99920 + \frac{0.99920}{2}} = 1.998$

Or pretty close to twice as fast.

#### Question: What does the computation of expected speed-up look like for 16 cores using our timings?

For 16 cores, we simply substitute the $2$ with $16$.

$\textrm{speed-up} = \frac{1}{1 - 0.99920 + \frac{0.99920}{16}} = 15.810$


## "One Final Question": What’s the slope of the line depicted in the speed-up data graph?

Looking at the graph, the slope remains pretty linear throughout the first 8 threads. The slow computation (rise over run) would be:

$\textrm{speed-up slope} = \frac{7.25 - 1}{8 - 1} = 0.892$

### Question: Does that linear trend continue as we add more threads? (Wait... wasn't the last question the final one?)

As we look at later points, we see the slope "flatten", or get smaller.

For 16 Threads:

$\textrm{speed-up slope} = \frac{10.25 - 1}{16 - 1} = 0.617$

For 32 Threads:

$\textrm{speed-up slope} = \frac{10.53 - 1}{32 - 1} = 0.307$

For 64 Threads:

$\textrm{speed-up slope} = \frac{10.47 - 1}{64 - 1} = 0.150$

### Question: What do you think causes the curve to “flatten out” when we use large thread counts?

The thread count appears to flatten as a result of the serial portion of the execution becoming a greater component of the overall execution time, and, ultimately, as we run out of cores to distribute the compute time amongst.  

Other factors may also be at play here. These other factors may include thread management overhead and the variability of the time slices given by the CPU as a result of things such as other processes running, relative priority of those processes, and interrupts that preempt our program's execution. The variablility factors begin to have a potential for greater impact on execution time as the total overall execution time gets smaller.


## The Moral of the Story

Unlike with linens, thread count matters.



