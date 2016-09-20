##STATS250 KEY FACTOR ANALYSIS
#Please answer the following question:  Other than GPAO, which variable(s) best predict the variable 
# for GRD_PTS_PER_UNIT for the course STATS 250 (SUBJECT="STATS" and CATALOG_NBR=250)? In other words, 
#what is the best predictor of a student's performance in STATS 250 other than the student's own GPA? 
require("dplyr")
require("ggplot2")
require("rstudioapi")
require("ggthemes")

library(MASS)
#set working directory to current .r file path
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

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

# HSGPA = 36? it most likely to be a error
# UM admit students with HSGPA 0?? or it should be NAs?

filter(student.record, HSGPA>4.0)

# many of those who have HSGPA = 0 have LAST_ACT_MATH_SCORE close to Max 
# Cloud be a evidence their HSGPA should be NA instead of 0.

count(filter(student.record, HSGPA< 1 & LAST_ACT_MATH_SCORE >34 ))

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



#Check and explorer the data
glimpse(S.A)
summary(S.A)
table(SEX)
summary(LAST_ACT_MATH_SCORE)

#There are 
count(filter(S.A, LAST_ACT_MATH_SCORE> 0 ))
#students have ACT math score, 
count(filter(S.A, LAST_SATI_MATH_SCORE> 0 ))
#students have SAT math score, but only 
count(filter(S.A, LAST_SATI_MATH_SCORE> 0 & LAST_ACT_MATH_SCORE> 0))
#students have both. 

#most students have ACT MATH Score
qplot(LAST_ACT_MATH_SCORE,colour = SEX,bins = 14,main = "Histogram for ACT MATH score by gender")
table(LAST_ACT_MATH_SCORE)
summary(LAST_SATI_MATH_SCORE)
summary(HSGPA)
hist(HSGPA)
hist(LAST_ACT_MATH_SCORE)
hist(LAST_SATI_MATH_SCORE)
qplot(LAST_ACT_MATH_SCORE,x =LAST_SATI_MATH_SCORE,colour = SEX)

p = ggplot(data = S.A, aes(y = LAST_SATI_MATH_SCORE, x = LAST_ACT_MATH_SCORE))
p + geom_point(aes(color = SEX)) +
  labs(title = "SAT MATH Vs. ACT MATH")+
  geom_smooth(method = "lm")+  theme_economist()


#normality check before model fitting
lillie.test(LAST_ACT_MATH_SCORE)
lillie.test(HSGPA)
lillie.test(LAST_SATI_MATH_SCORE)
lillie.test(GRD_PTS_PER_UNIT)

#model selection

S.A.reduce <- select(S.A.c,4,12:21)
names(S.A.c)



fullmodel <- lm(data = S.A.reduce, GRD_PTS_PER_UNIT~.)
step(fullmodel)

model.select(fullmodel,sig = 0.0000001)

extractAIC(fullmodel)
fit.GRD <- lm(data = S.A, GRD_PTS_PER_UNIT~HSGPA + LAST_ACT_MATH_SCORE+SEX)
summary(fit.GRD)

S.A.c<- filter(S.A, HSGPA>0 & LAST_ACT_MATH_SCORE > 0)
fit.GRDc <- lm(data = S.A.c, GRD_PTS_PER_UNIT~HSGPA + LAST_ACT_MATH_SCORE+SEX)
summary(fit.GRDc)
qplot(HSGPA,colour = SEX,bins = 40)

 
fit.SatVsAct <- lm(LAST_SATI_MATH_SCORE~LAST_ACT_MATH_SCORE) 
plot(fit.SatVsAct)


barplot(student.course$CATALOG_NBR)

hist(student.record$HSGPA)
summary(student.record$LAST_SATI_VERB_SCORE)
summary(student.record$LAST_SATI_MATH_SCORE)
summary(student.record$LAST_ACT_COMP_SCORE)

count(filter(S.A, LAST_ACT_MATH_SCORE> 0 ))

  fit.GRDe <- lm(data = S.A.c, GRD_PTS_PER_UNIT~LAST_SATI_VERB_SCORE);summary(fit.GRDe)

fit.GRD <- lm(data = S.A, GRD_PTS_PER_UNIT~HSGPA + LAST_ACT_MATH_SCORE+SEX)
summary(fit.GRD)

fit.GRDb <- lm(data = S.A.c, GRD_PTS_PER_UNIT~HSGPA +LAST_ACT_COMP_SCORE+ LAST_ACT_MATH_SCORE +SEX)
summary(fit.GRDb)

S.A.c<- filter(S.A, HSGPA>0 & LAST_ACT_MATH_SCORE > 0)
fit.GRDc <- lm(data = S.A.c, GRD_PTS_PER_UNIT~HSGPA + LAST_ACT_MATH_SCORE+SEX)
summary(fit.GRDc)

fit.GRDd <- lm(data = S.A.c, GRD_PTS_PER_UNIT~HSGPA +LAST_ACT_COMP_SCORE+LAST_ACT_READ_SCORE+ LAST_ACT_MATH_SCORE +SEX)
summary(fit.GRDd)

  fit.GRDe <- lm(data = S.A.c, GRD_PTS_PER_UNIT~HSGPA +LAST_ACT_SCIRE_SCORE+LAST_ACT_COMP_SCORE+LAST_ACT_READ_SCORE+ LAST_ACT_MATH_SCORE + +SEX)
summary(fit.GRDe)



