##STATS250 KEY FACTOR ANALYSIS
#Please answer the following question:  Other than GPAO, which variable(s) best predict the variable 
# for GRD_PTS_PER_UNIT for the course STATS 250 (SUBJECT="STATS" and CATALOG_NBR=250)? In other words, 
#what is the best predictor of a student's performance in STATS 250 other than the student's own GPA? 
require("dplyr")
require(ggplot2)
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

#loading data into Environment
student.course <- read.csv("PLA-MOOC/student.course.csv")
student.record <- read.csv("PLA-MOOC/student.record.csv")

summary(student.record)
summary(student.course)

# = 36? it most likely to be a error
# UM admit students with HSGPA 0?? or it should be NAs?
filter(student.record, HSGPA>4.0)
# many of those who have HSGPA = 0 have LAST_ACT_MATH_SCORE close to Max 
# Cloud be a evidence their HSGPA should be NA instead of 0.

summary(filter(student.record, HSGPA< 1 & LAST_ACT_MATH_SCORE >35 ))

#prepare data for dplyr
Course <-tbl_df(student.course)
Record <-tbl_df(student.record)

#getting to know the dataset's big picture
glimpse(Course)
glimpse(Record)
names(Course)
names(Record)
levels(Course$SUBJECT)

#select only the data required for look into STATS 250
STATS250 = filter(Course,SUBJECT =='STATS' & CATALOG_NBR == '250')
#aggregate the 'Record' and 'Course' table by the Anonymous ID
S.A = STATS250.Aggregate <- inner_join(STATS250,Record,by = 'ANONID')
attach(S.A)
#Check
glimpse(S.A)
summary(S.A)
summary(SEX)
summary(LAST_ACT_MATH_SCORE)
summary(LAST_SATI_MATH_SCORE)
summary(HSGPA)
hist(HSGPA)
hist(LAST_ACT_MATH_SCORE)
hist(LAST_SATI_MATH_SCORE)
qplot(LAST_ACT_MATH_SCORE,x =LAST_SATI_MATH_SCORE)


qplot(HSGPA)

 
fit.SatVsAct <- lm(LAST_SATI_MATH_SCORE~LAST_ACT_MATH_SCORE+HSGPA+SEX) 
plot(fit.SatVsAct)


hist(student.course$CATALOG_NBR)

hist(student.record$HSGPA)
summary(student.record$LAST_SATI_VERB_SCORE)
summary(student.record$LAST_SATI_MATH_SCORE)
summary(student.record$LAST_ACT_COMP_SCORE)
filter(student.record, HSGPA>4.0)

require(psych)
myData <- S.A
describe(myData)
pairs.panels(myData)
lowerCor(myData)

fa(myData)
