returnModel <- function(csv){
  
  require(dplyr)
  mergeData <- csv %>% select(-c(X,Date,Account,Channel,Units,year))
  
  ## Converting non numeric features to numeric
  mergeData$hour <- as.numeric(mergeData$hour)
  mergeData$month <- as.numeric(mergeData$month)
  mergeData$Day.of.Week <-  as.numeric(mergeData$Day.of.Week)
  mergeData$weekday <-  as.numeric(mergeData$weekday)
  mergeData$PeakHour <- as.numeric(mergeData$PeakHour)
  mergeData$day <- as.numeric(mergeData$day)
  
  str(mergeData)
  
  ## Taking the subset of the data frame which only contains numeric features, removing categorical variables
  merge.sel <- subset(mergeData,select = -c(Conditions,Wind_Direction))
 
  
  set.seed(2014)
  library(caret)
  library(klaR)
  
  
  train.size <- 0.8
  train.index <- sample.int(length(merge.sel$Kwh),round(length(merge.sel$Kwh)*train.size))
  train.sample <- merge.sel[train.index,]
  train.val <- merge.sel[-train.index,]
  
  # define training control
  train_control <- trainControl(method="cv", number=3)
  lambdaGrid <- expand.grid(lambda = 10^seq(10, -2, length=100))
  
  # train the model using Ridge regularization
  
  model <- train(Kwh ~ hour + month + Day.of.Week + weekday + PeakHour + TemperatureF + Dew_PointF + Humidity + Sea_Level_PressureIn
               + VisibilityMPH , data = train.sample, trControl=train_control,method = "ridge",tuneGrid = lambdaGrid,preProcess=c('center', 'scale'))
  # As we can see this ridge regression fit certainly has lower RMSE and higher R^2. We can also see that the ridge regression has indeed shrunk the coefficients, some of them extremely close to zero.
  # predict(model$finalModel,type = 'coef',mode = 'norm')$coefficients[10,] # Gives the coefficents of the
  
  return(model)
}