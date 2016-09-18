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
glimpse(Record)
names(Course)
names(Record)
levels(Course$SUBJECT)
STATS250 = filter(Course,SUBJECT =='STATS' & CATALOG_NBR == '250')

S.A = STATS250.Aggregate <- inner_join(STATS250,Record,by = 'ANONID')

summary(S.A)

fit <- lm(GRD_PTS_PER_UNIT~ HSGPA +
            LAST_ACT_ENGL_SCORE+
            LAST_ACT_MATH_SCORE+
            LAST_ACT_READ_SCORE  ,data = S.A)
summary(fit)
# fit <- princomp(S.A, cor=TRUE)
# summary(fit) # print variance accounted for 
# loadings(fit) # pc loadings 
# plot(fit,type="lines") # scree plot 
# fit$scores # the principal components
# biplot(fit)

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
