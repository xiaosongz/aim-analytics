##STATS250 KEY FACTOR ANALYSIS
#Please answer the following question:  Other than GPAO, which variable(s) best predict the variable 
# for GRD_PTS_PER_UNIT for the course STATS 250 (SUBJECT="STATS" and CATALOG_NBR=250)? In other words, 
#what is the best predictor of a student's performance in STATS 250 other than the student's own GPA? 
sourceDir <- function(path, trace = TRUE, ...) {
  for (nm in list.files(path, pattern = "[.][RrSsQq]$")) {
    if(trace) cat(nm,":")
    source(file.path(path, nm), ...)
    if(trace) cat("\n")
  }
}

sourceDir('PLA-MOOC')

student.course <- read.csv("~/GitHub/aim-analytics/PLA-MOOC/student.course.csv")
student.record <- read.csv("~/GitHub/aim-analytics/PLA-MOOC/student.record.csv")

require("dplyr")
Course <-tbl_df(student.course)
Record <-tbl_df(student.record)
glimpse(Course)
names(Course)
levels(Course$SUBJECT)
STATS250 = filter(Course,SUBJECT =='STATS' & CATALOG_NBR == '250')

STATS250.Aggregate <- inner_join(STATS250,Record,by = 'ANONID')

dim(STATS250.Aggregate)
compute.overall.grade.penalty(STATS250.Aggregate)
