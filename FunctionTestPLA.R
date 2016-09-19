require("dplyr")
#sourceDir is use to source all .r file under same Dir all in once
sourceDir <- function(path, trace = TRUE, ...) {
  for (nm in list.files(path, pattern = "[.][RrSsQq]$")) {
    if(trace) cat(nm,":")
    source(file.path(path, nm), ...)
    if(trace) cat("\n")
  }
}
#Source all functions uder PLA-MOOC into R-Environment for future use.
sourceDir('PLA-MOOC')


 sr <- read.csv("PLA-MOOC/student.record.csv")
 sc <- read.csv("PLA-MOOC/student.course.csv")
 out <- grade.penalty(sr,sc,'STATS',250,GROUP='GENDER',REGRESSION=TRUE,MATCHING=TRUE,PDF=FALSE)
 
 S.A
 grades.lm <- lm(G3 ~ ., data = grades.train)