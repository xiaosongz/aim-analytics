library(rbenchmark)
library(dplyr)

sr = student.record ;sc = student.course
x = benchmark(replications = 100, order = "elapsed",
   merge = merge(sc, sr,by = 'ANONID'),
   dplyr = inner_join(sc, sr,by = 'ANONID'))

x
# Results were collected from a rMBP with 2.6 GHz (i5-4278U)Haswell processor with 3 MB shared L3 cache
# test replications elapsed relative user.self sys.self user.child sys.child
# 2 dplyr           10   4.510     1.00     3.653    0.835          0         0
# 1 merge           10  40.408     8.96    35.978    4.090          0         0
# Results showing a 88.8% decreasing in cpu time (x[2,3]-x[1,3])/x[2,3] [1] 0.8883884 
(x[2,3]-x[1,3])/x[2,3]

#Results were collected from a Desktop with 4.5 GHz i7-6700K 
# test replications elapsed relative user.self sys.self user.child sys.child
# 2 dplyr          100   16.70    1.000     13.53     3.17         NA        NA
# 1 merge          100  280.96   16.824    265.20    15.64         NA        NA
# > (x[2,3]-x[1,3])/x[2,3]
# [1] 0.9405609
#Results showing a 94% decreasing in cpu time 