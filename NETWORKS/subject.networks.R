#this takes the student course and student record tables as inputs
#and creates
#sc : student course
#sr : student record
#ADMIT_TERM: which cohort of students to consider
#COURSE_TERM: which TERM to consider for a given cohort
#title: title to add to plot(s)
#
#packages: gplots,circlize,igraph
#
#EXAMPLE: R> out <- subject.networks(sr,sc)
#
############
subject.networks <- function(sr,sc,ADMIT_TERM=1810,COURSE_TERM=1810,title='NONE')
{
 
  library(gplots)                       #call the library containing heatmap.2
  library(circlize)                     #chordDiagram library
  library(igraph)                       #all the networking stuff we need.
  
  #Get the courses we want
  e <- sc$TERM == COURSE_TERM
  sc <- sc[which(e),]
  
  #Get the cohort of students
  e <- sr$ADMIT_TERM == ADMIT_TERM
  sr <- sr[which(e),]
  
  #Create an numbered index for each subect in student-course table. This eases 
  #matrix indexing down the road.
  print('creating subject index')
  sc   <- create.subject.index(sc)
  nsub <- max(sc$SUBSHORT)                                     #number of SUBJECTS
  SUBLIST <- as.character(sc$SUBJECT[!duplicated(sc$SUBJECT)]) #the list of unique subjects
  
  print('merging and setting up')
  data <- merge(sr,sc,by='EMPLID',all.x=TRUE) #Now merge the course list with the student list
  e    <- !is.na(data$SUBJECT)
  data <- data[which(e),]
  
  #This is all set-up for efficient construction of the matrix we will need to begin building networks.
  data        <- data[order(data$EMPLID,data$SUBSHORT), ]       #sort the data frame by EMPLID, then SUBSHORT
  COUNT1  <- sequence(rle(as.vector(data$EMPLID))$lengths)      #Count the runs of EMPLID
  COUNT2  <- sequence(rle(as.vector(data$SUBSHORT))$lengths)    #Count the runs of SUBSHORT within EMPLID
  data <- data.frame(data,COUNT1,COUNT2,stringsAsFactors=FALSE) #Add the COUNTS to the data frame
  ntot        <- length(data$EMPLID)                            #Total number of rows in the data frame
  nid     <- length(data$EMPLID[!duplicated(data$EMPLID)])      #Total number of unique EMPLID
  nstart  <- which(data$COUNT1 == 1)                            #Keep track of when a new run of EMPLID starts
  nstart2 <- which(data$COUNT2 == 1)                            #Keep track of when a new run of SUBSHORT starts
  #done with setup.
  
  CMTX    <- mat.or.vec(nid,nsub) #The matrix we will fill
  
  print('looping over students')
  for (i in 1:nid) #loop over all EMPLIDs
  {
    
    start_ind <- nstart[i]
    if (i < nid){stop_ind  <- nstart[i+1]-1}
    if (i == nid){stop_ind <- ntot}
    ind <- c(start_ind:stop_ind)
    
    sub <- data[ind,]
    nstsub <- which(sub$COUNT2 == 1)
    nssb   <- length(nstsub)
    
    if (nssb > 0)
    {
      for (j in 1:nssb) #Loop over all subjects
      {
        
        start_ind2 <- nstsub[j]
        if (j < nssb) {stop_ind2  <- nstsub[j+1]-1}
        if (j == nssb){stop_ind2 <- length(ind) }#length(c(start_ind2:stop_ind2))}
        
        CMTX[i,sub$SUBSHORT[start_ind2]] <- length(c(start_ind2:stop_ind2)) #The number of courses student i took in subject j.
                                                                            #This makes uses of hte SUBSHORT index
        }
    }
  }
  
  colnames(CMTX) <- SUBLIST #name the columns of the matrix
  csum <- colSums(CMTX)     #Count the number of students that took each subject
  n <- 250                  #only keep subjects with more than n studnets, e.g. "high enrollment"
  print(paste('cutting subject matrix at ',n,sep=""))
  e <- as.numeric(csum) > n
  
  CMTX <- CMTX[,e]          #Reduce the matrix to include only the high enrollment courses.
  
  a1 <- t(CMTX) %*% CMTX    #take outer product of CMTX to compute the covariance matrix
  a1 <- cov2cor(a1)         #compute the correlation matrix from the covariance matrix (i.e. divide by diagonals)
  heatmap.2(a1,trace='none',main=title) #plot the heatmap
  
  
  #Now create networks for different correlation thresholds
  for (i in 1:10)
  {
    thresh <- 0.05*i+0.1     #set the correlation threshold
    temp <- a1               #keep a copy of the correaltion matrix
    diag(temp) <- 0          #set the diagongals to zero
    e1 <- temp <= thresh     #find which cells are less than the threshold
    e2 <- temp > thresh      #find which cells are greater than the threshold
    temp[e1] <- 0            #Set these cells accordingly
    temp[e2] <- 1
    
    #temp is now the ADAJECENCY MATRIX
    hh <- graph_from_adjacency_matrix(temp,mode='undirected')       #compute the network, store the object in hh
    ncl <- clusters(hh)$no                                          #count the number of clusters
    nettitle <- paste('Subject Clustering: rho > ',thresh,', NCl = ',ncl) #create a title
    plot(hh,main=nettitle)
    
    #if i = 3, keep some intermediate stuff to output for further analysis
    if (i == 3)
    {
      gobj <- hh
      adj  <- temp
    }
    
  }
  
  chordDiagram(adj,directional=TRUE,symmetric=TRUE)
  
  return(gobj)
}

#create by-subject index that will speed up matrix indexing
create.subject.index <- function(data)
{
  data       <- data[order(data$SUBJECT), ]
  data$count <- sequence(rle(as.vector(data$SUBJECT))$lengths)
  ntot       <- length(data$SUBJECT)
  
  nid    <- length(data$SUBJECT[!duplicated(data$SUBJECT)])
  nstart <- which(data$count == 1)
  
  SUBSHORT  <- mat.or.vec(ntot,1)
  NTAKEN    <- mat.or.vec(ntot,1)
  
  for (i in 1:nid)
  {
    start_ind <- nstart[i]
    if (i < nid){stop_ind  <- nstart[i+1]-1}
    if (i == nid){stop_ind <- ntot}
    ind        <- c(start_ind:stop_ind)
    SUBSHORT[ind] <- i
    NTAKEN[ind] <- length(ind)
  }
  
  return(data.frame(data,SUBSHORT))
  
}
