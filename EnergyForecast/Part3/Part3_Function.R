#####Part 3) Predict Energy usage from tranied model on a new data set
## Adding Model Source function Which reads a CSV to train the model
source("ModelFunction.R")

WeatherData <- read.csv("forecastData.csv",header = TRUE)

## Data looks like this
head(WeatherData)

##Lets use Lubridate package to find the date and hour
library(lubridate)

WeatherData$date = date(WeatherData$Time)
WeatherData$hour = hour(WeatherData$Time)

summary(WeatherData)

require(dplyr)
WeatherData <- WeatherData %>% select(-c(X,Time,TimeEDT,Wind_Direction,Wind_SpeedMPH,Gust_SpeedMPH,PrecipitationIn,Events,Conditions,WindDirDegrees,DateUTC))

checkWeekday <- function(date){
  a = if((wday(date) == 6 || wday(date) == 7)) 0 else 1
  return(a)
}

cal_PeakHour <- function(hour){
  p = if(hour > 6 & hour < 20) 1 else 0
  return(p)
}

require(lubridate)
WeatherData <- WeatherData %>%
  mutate(month = lubridate::month(date),day = lubridate::day(date),'Day.of.Week' = wday(date)) %>%
  mutate(weekday = sapply(date, function(x) checkWeekday(x))) %>%
  mutate(PeakHour = sapply(hour,function(x) cal_PeakHour(x)))


WeatherData$TemperatureF <- as.numeric(WeatherData$TemperatureF)
WeatherData$Dew_PointF <- as.numeric(WeatherData$Dew_PointF)
WeatherData$Sea_Level_PressureIn <- as.numeric(WeatherData$Sea_Level_PressureIn)
WeatherData$VisibilityMPH <- as.numeric(WeatherData$VisibilityMPH)
WeatherData$Humidity <- as.numeric(WeatherData$Humidity)
WeatherData$hour <- as.numeric(WeatherData$hour)
WeatherData$day <- as.numeric(WeatherData$day)


## We need our data to fall in normal range to remove outliers
##                        MIN   MAX
##    TempF	                0	  100
##    DewPointF	          -20	  80
##    Humidity	           10	  100
##    Sea_Level_Pressure	 28	  32
##    Visibility	          0   10
##    Wind_Speed	          0 	50

#### Function to relace oulier value Attached. We will use the approach of subsituting the previous or the next value of the observation
## For example, if the record 8999 has Temperature as -9999 we will use the record of 8998 so that this is still acceptable


remove_out <- function(param,index,min_v,max_v){
  val = NULL
  val = param[index]
  if(val < min_v | val > max_v | is.na(val)){
    if(index-1 >= 1){
      val = param[index-1]
    } else if (index-1 <= 0){
      val = param[index+1]
    } 
    return(val)
  } else{
    print("Nothing changed")
    return(val)  #Normal Value return
  }
}

## Lets remove some outliers for Temperature. We will find out the records where Temperature is falling out of the range defined in the table


## Temperature
index <- which(WeatherData$TemperatureF < 0 | WeatherData$TemperatureF > 100 | is.na(WeatherData$TemperatureF))

for (i in index){
  WeatherData$TemperatureF[i] = remove_out(WeatherData$TemperatureF,i,0,100)
}

## Dew Point
index <- which(WeatherData$Dew_PointF < -20 | WeatherData$Dew_PointF > 80 | is.na(WeatherData$Dew_PointF))
for (i in index){
  WeatherData$Dew_PointF[i] = remove_out(WeatherData$Dew_PointF,i,-20,80)
}

## Humidity
index <- which(WeatherData$Humidity < 10 | WeatherData$Humidity > 100 | is.na(WeatherData$Humidity))
for (i in index){
  WeatherData$Humidity[i] = remove_out(WeatherData$Humidity,i,10,100)
}


## Sea_Level_Pressure
index <- which(WeatherData$Sea_Level_PressureIn < 28 | WeatherData$Sea_Level_PressureIn > 32 | is.na(WeatherData$Sea_Level_PressureIn))
for (i in index){
  WeatherData$Sea_Level_PressureIn[i] = remove_out(WeatherData$Sea_Level_PressureIn,i,28,32)
}

## VisibilityMPH
index <- which(WeatherData$VisibilityMPH < 0 | WeatherData$VisibilityMPH > 10 | is.na(WeatherData$VisibilityMPH))
for (i in index){
  WeatherData$VisibilityMPH[i] = remove_out(WeatherData$VisibilityMPH,i,0,10)
}


WeatherData.Agg <- WeatherData %>%  group_by(date,hour,month,day,Day.of.Week,weekday,PeakHour) %>% 
  summarise(TemperatureF = mean(TemperatureF),
            Dew_PointF = mean(Dew_PointF),
            Humidity = mean(Humidity),
            Sea_Level_PressureIn = mean(Sea_Level_PressureIn),
            VisibilityMPH = mean (VisibilityMPH))

write.csv(WeatherData.Agg, "ForeCastInput_ModelData.csv")

head(WeatherData.Agg)

## This is the cleaned version of the Data, we can apply our model here
## Calling the Model function with our dataset that can be trained

TrainingData <- read.csv("MergedDataCopy.csv",header = TRUE)

model <- returnModel(TrainingData)

## Predicting the values of the WeatherData based on the trained Model

WeatherData.Agg$KwH <- predict(model,newdata = WeatherData.Agg)

write.csv(WeatherData.Agg[,c("date","hour","TemperatureF","KwH")],"ForecastOutput_26435791004.csv")

