library(data.table)
library(reshape2)
# download file and unzip
#url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
#file<- "Dataset.zip"
#file1 <- paste("./",file,sep="")
#download.file(url,destfile=file1, method="curl")
#cmd<-paste("gzip", file, sep=" ")
#system(cmd)
# set directory for analysis
##dir<-"/Users/ron/UCI HAR Dataset/"
##dirtrain<-"/Users/ron/UCI HAR Dataset/train/"
##dirtest<-"/Users/ron/UCI HAR Dataset/test/"
# read data
wdir=getwd()
dirdata=paste(wdir,"/UCI HAR Dataset/", sep="")
dirtrain<-paste(dirdata,"train/", sep="")
dirtest<-paste(dirdata,"test/", sep="") 
f1_subject_train <-fread(paste(dirtrain,"subject_train.txt", sep=""))
f1_subject_test <- fread(paste(dirtest,"subject_test.txt",sep=""))
f1_activity_train <-fread(paste(dirtrain,"Y_train.txt",sep=""))
f1_activity_test <-fread(paste(dirtest,"Y_test.txt",sep=""))
# combine subject training and test data
f1_subject <- rbind(f1_subject_train, f1_subject_test)
# setting the name of the object
setnames(f1_subject,"V1", "subject")
# combine activity training and test data 
f1_activity<-rbind(f1_activity_train, f1_activity_test)
setnames(f1_activity,"V1", "activityNum")
# read data files
f1_train_1 <-read.table(paste(dirtrain,"X_train.txt",sep=""))
f1_train <-data.table(f1_train_1)
f1_test_1 <-read.table(paste(dirtest,"X_test.txt",sep=""))
f1_test <-data.table(f1_test_1)
# combine training and test data
f2 <- rbind(f1_train,f1_test)
f1_subject<-cbind(f1_subject,f1_activity)
# add f1_subject data to first columns of f2  
f2 <- cbind(f1_subject,f2)
# sort 
setkey(f2,subject,activityNum)
#read features and 
f1_features <- fread(paste(dir, "features.txt",sep=""))
setnames(f1_features, names(f1_features), c("featureNum", "featureName"))
#subsetting for only the mean/std
f1_features <- f1_features[grepl("mean\\(\\)|std\\(\\)", featureName)]
# converting to match f2
f1_features$featureCode <- f1_features[, paste("V", featureNum, sep="")]
#subset with names
select <- c(key(f2), f1_features$featureCode)
f2 <- f2[, select, with = FALSE]
# read activity labels
f1_activityNames <- fread(file.path(dir, "activity_labels.txt"))
setnames(f1_activityNames, names(f1_activityNames), c("activityNum", "activityName"))
# merge activity label
f2 <- merge(f2, f1_activityNames, by = "activityNum", all.x = TRUE)
#sort
setkey(f2, subject, activityNum, activityName)
# reshaping format 
f2 <- data.table(melt(f2, key(f2), variable.name = "featureCode"))
f2 <- merge(f2, f1_features[, list(featureNum, featureCode, featureName)], by = "featureCode", 
            all.x = TRUE)
f2$activity <- factor(f2$activityName)
f2$feature <- factor(f2$featureName)


# features with 1 category
f2$featJerk <- factor(grepl("Jerk",f2$feature), labels = c(NA, "Jerk"))
f2$featMagnitude <- factor(grepl("Mag",f2$feature), labels = c(NA, "Magnitude"))

# features with 2 categories - need to separate out the features
# Time and Fgetwd
requency = 2; n=2
# Using grepl - pattern matching to extract "^t" time, and "^f" frequency
nf <- 2
a <- matrix(seq(1, nf), nrow = nf)
b <- matrix(c(grepl("^t",f2$feature), grepl("^f",f2$feature)), ncol = nrow(a))
# using factor to create Time/Freq value replacement for logicals (True/False on grep)
f2$featDomain <- factor(b %*% a, labels = c("Time", "Freq"))
# Using grepl - pattern matching to extract "Acc" and "Gyro"
b <- matrix(c(grepl("Acc",f2$feature), grepl("Gyro",f2$feature)), ncol = nrow(a))
f2$featInstrument <- factor(b %*% a, labels = c("Accelerometer", "Gyroscope"))
# similar approach to BodyAcc/Gravity Acc
b <- matrix(c(grepl("BodyAcc",f2$feature), grepl("GravityAcc",f2$feature)), ncol = nrow(a))
f2$featAcceleration <- factor(b %*% a, labels = c(NA, "Body", "Gravity"))
# similar approach to Mean/Std
b <- matrix(c(grepl("mean()",f2$feature), grepl("std()",f2$feature)), ncol = nrow(a))
f2$featVariable <- factor(b %*% a, labels = c("Mean", "SD"))

## Features with 3 categories
nf <- 3
a <- matrix(seq(1, nf), nrow = nf)
b <- matrix(c(grepl("-X",f2$feature), grepl("-Y",f2$feature), grepl("-Z",f2$feature)), ncol = nrow(a))
f2$featAxis <- factor(b %*% a, labels = c(NA, "X", "Y", "Z"))

#sort
setkey(f2, subject, activity, featDomain, featAcceleration, featInstrument, 
       featJerk, featMagnitude, featVariable, featAxis)
# complete tidy dataset
ans_tidy0 <- f2[, list(count = .N, average = mean(value)), by = key(f2)]
write.csv(ans_tidy0,file=paste(dirdata,"run_analysis_out.csv", sep=""))
