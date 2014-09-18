run_analysis
============
Last updated 2014-09-17 22:59:53 using R version 3.1.1 (2014-07-10).


Instructions for project
------------------------

> The purpose of this project is to demonstrate your ability to collect, work with, and clean a data set. The goal is to prepare tidy data that can be used for later analysis. You will be graded by your peers on a series of yes/no questions related to the project. You will be required to submit: 1) a tidy data set as described below, 2) a link to a Github repository with your script for performing the analysis, and 3) a code book that describes the variables, the data, and any transformations or work that you performed to clean up the data called CodeBook.md. You should also include a README.md in the repo with your scripts. This repo explains how all of the scripts work and how they are connected.  
> 
> One of the most exciting areas in all of data science right now is wearable computing - see for example this article . Companies like Fitbit, Nike, and Jawbone Up are racing to develop the most advanced algorithms to attract new users. The data linked to from the course website represent data collected from the accelerometers from the Samsung Galaxy S smartphone. A full description is available at the site where the data was obtained: 
> 
> http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones 
> 
> Here are the data for the project: 
> 
> https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip 
> 
> You should create one R script called run_analysis.R that does the following. 
> 
> 1. Merges the training and the test sets to create one data set.
> 2. Extracts only the measurements on the mean and standard deviation for each measurement.
> 3. Uses descriptive activity names to name the activities in the data set.
> 4. Appropriately labels the data set with descriptive activity names.
> 5. Creates a second, independent tidy data set with the average of each variable for each activity and each subject. 
> 



Preliminaries
-------------

Load packages.


```r
library(data.table)
library(reshape2)
```

Get the data
------------

Download the file. Put it in the `Data` folder. 


```r
path<-getwd()
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
file <- "Dataset.zip"
file1 <- paste(path,file,sep="")
if (!file.exists(path)) {dir.create(path)}
download.file(url, destfile=file1, method="curl")
```

Unzip the file. 


```r
cmd <- paste("unzip",file,sep=" ")
system(cmd)
```

The archive put the files in a folder named `UCI HAR Dataset`. Set this folder as the input path. List the files here.


```r
wdir=getwd()
dirdata<-paste(wdir,"/UCI HAR Dataset/", sep="")
dirtrain<-paste(dirdata,"train/", sep="")
dirtest<-paste(dirdata,"test/", sep="") 
list.files(dirdata, recursive=TRUE)
```

```
##  [1] "activity_labels.txt"                         
##  [2] "features_info.txt"                           
##  [3] "features.txt"                                
##  [4] "README.txt"                                  
##  [5] "test/Inertial Signals/body_acc_x_test.txt"   
##  [6] "test/Inertial Signals/body_acc_y_test.txt"   
##  [7] "test/Inertial Signals/body_acc_z_test.txt"   
##  [8] "test/Inertial Signals/body_gyro_x_test.txt"  
##  [9] "test/Inertial Signals/body_gyro_y_test.txt"  
## [10] "test/Inertial Signals/body_gyro_z_test.txt"  
## [11] "test/Inertial Signals/total_acc_x_test.txt"  
## [12] "test/Inertial Signals/total_acc_y_test.txt"  
## [13] "test/Inertial Signals/total_acc_z_test.txt"  
## [14] "test/subject_test.txt"                       
## [15] "test/X_test.txt"                             
## [16] "test/y_test.txt"                             
## [17] "train/Inertial Signals/body_acc_x_train.txt" 
## [18] "train/Inertial Signals/body_acc_y_train.txt" 
## [19] "train/Inertial Signals/body_acc_z_train.txt" 
## [20] "train/Inertial Signals/body_gyro_x_train.txt"
## [21] "train/Inertial Signals/body_gyro_y_train.txt"
## [22] "train/Inertial Signals/body_gyro_z_train.txt"
## [23] "train/Inertial Signals/total_acc_x_train.txt"
## [24] "train/Inertial Signals/total_acc_y_train.txt"
## [25] "train/Inertial Signals/total_acc_z_train.txt"
## [26] "train/subject_train.txt"                     
## [27] "train/X_train.txt"                           
## [28] "train/y_train.txt"
```

Read the subject files.


```r
f1_subject_train <-fread(paste(dirtrain,"subject_train.txt",sep=""))
f1_subject_test <-fread(paste(dirtest,"subject_test.txt",sep=""))
```

Read the activity files


```r
f1_activity_train <-fread(paste(dirtrain,"Y_train.txt",sep=""))
f1_activity_test <-fread(paste(dirtest,"Y_test.txt",sep=""))
```

Combine activity training and test data 


```r
f1_subject <- rbind(f1_subject_train, f1_subject_test)
setnames(f1_subject,"V1", "subject")
f1_activity<-rbind(f1_activity_train, f1_activity_test)
setnames(f1_activity,"V1", "activityNum")
```

Read and Concatenate the data tables.


```r
f1_train_1 <-read.table(paste(dirtrain,"X_train.txt",sep=""))
f1_train <-data.table(f1_train_1)
f1_test_1 <-read.table(paste(dirtest,"X_test.txt",sep=""))
f1_test <-data.table(f1_test_1)
f2 <- rbind(f1_train,f1_test)
```

Merge the training and the test sets
------------------------------------

Merge columns.


```r
f1_subject<-cbind(f1_subject,f1_activity)
f2 <- cbind(f1_subject,f2)
```

Set key.


```r
setkey(f2,subject,activityNum)
```

Extract only the mean and standard deviation
--------------------------------------------

Read the `features.txt` file


```r
f1_features <- fread(paste(dirdata, "features.txt",sep=""))
setnames(f1_features, names(f1_features), c("featureNum", "featureName"))
```

Subset only measurements for the mean and standard deviation


```r
f1_features <- f1_features[grepl("mean\\(\\)|std\\(\\)", featureName)]
```

Convert the column numbers to a vector of variable names matching columns


```r
f1_features$featureCode <- f1_features[, paste("V", featureNum, sep="")]
head(f1_features)
```

```
##    featureNum       featureName featureCode
## 1:          1 tBodyAcc-mean()-X          V1
## 2:          2 tBodyAcc-mean()-Y          V2
## 3:          3 tBodyAcc-mean()-Z          V3
## 4:          4  tBodyAcc-std()-X          V4
## 5:          5  tBodyAcc-std()-Y          V5
## 6:          6  tBodyAcc-std()-Z          V6
```

```r
f1_features$featureCode
```

```
##  [1] "V1"   "V2"   "V3"   "V4"   "V5"   "V6"   "V41"  "V42"  "V43"  "V44" 
## [11] "V45"  "V46"  "V81"  "V82"  "V83"  "V84"  "V85"  "V86"  "V121" "V122"
## [21] "V123" "V124" "V125" "V126" "V161" "V162" "V163" "V164" "V165" "V166"
## [31] "V201" "V202" "V214" "V215" "V227" "V228" "V240" "V241" "V253" "V254"
## [41] "V266" "V267" "V268" "V269" "V270" "V271" "V345" "V346" "V347" "V348"
## [51] "V349" "V350" "V424" "V425" "V426" "V427" "V428" "V429" "V503" "V504"
## [61] "V516" "V517" "V529" "V530" "V542" "V543"
```

Subset these variables using variable names


```r
select <- c(key(f2), f1_features$featureCode)
f2 <- f2[, select, with = FALSE]
```


Use descriptive activity names
------------------------------

Read `activity_labels.txt` file


```r
f1_activityNames <- fread(file.path(dirdata, "activity_labels.txt"))
setnames(f1_activityNames, names(f1_activityNames), c("activityNum", "activityName"))
```


Label with descriptive activity names
-----------------------------------------------------------------

Merge activity labels.


```r
f2 <- merge(f2, f1_activityNames, by = "activityNum", all.x = TRUE)
```

Add `activityName` as a key.


```r
setkey(f2, subject, activityNum, activityName)
```

Melt the data table to reshape it from a short and wide format to a tall and narrow format.


```r
f2 <- data.table(melt(f2, key(f2), variable.name = "featureCode"))
```

Merge activity name.


```r
f2 <- merge(f2, f1_features[, list(featureNum, featureCode, featureName)], by = "featureCode", 
            all.x = TRUE)
```

Create a new variable, `activity` that is equivalent to `activityName` as a factor class.
Create a new variable, `feature` that is equivalent to `featureName` as a factor class.


```r
f2$activity <- factor(f2$activityName)
f2$feature <- factor(f2$featureName)
```

Separate out Features


```r
## Features with 1 category
f2$featJerk <- factor(grepl("Jerk",f2$feature), labels = c(NA, "Jerk"))
f2$featMagnitude <- factor(grepl("Mag",f2$feature), labels = c(NA, "Magnitude"))

## Features with 2 categories
frequency = 2; n=2
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
```

Create a tidy data set
----------------------

Create a data set with the average of each variable for each activity and each subject.


```r
setkey(f2, subject, activity, featDomain, featAcceleration, featInstrument, 
       featJerk, featMagnitude, featVariable, featAxis)
# complete tidy dataset
ans_tidy0 <- f2[, list(count = .N, average = mean(value)), by = key(f2)]
```

Make codebook.


```r
knit("makeCodebook.Rmd", output="codebook.md", encoding="ISO8859-1", quiet=TRUE)
```

```
## [1] "codebook.md"
```

```r
markdownToHTML("codebook.md", "codebook.html")
```
