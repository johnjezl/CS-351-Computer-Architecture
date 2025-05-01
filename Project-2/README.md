# Project 2

## Description
This project explores increasing performance by increasing parallelism of execution. In this case, using threading.  The hashing algorithm `hash-04` from Project 1 is parallelized to different degrees (i.e. the number of simultaneous threads are varied) to see how far threading can be productively taken. 

## Process
Similar to Project 1, the hashing program is run using the `time` utility to collect runtime information. Unlike Project 1, a thread count is specified over which the hashing load is distributed. `hash04` is executed multiple times, with the number of threads being increased for each run. This allows us to see at what point the performance benefit drops off and/or regresses.

## Results

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



