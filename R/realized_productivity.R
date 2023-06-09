# -*- coding: UTF-8 -*-
#' @title Calculate the realized productivity.
#' @description realized.productivity calculate the realized productivity of each stand based on model parameters (obtained from the parameterOutput function).
#' @details realized.productivity takes data,data_BA,data_V parameters as required inputs.
#' @param forestData A forestData class data
#' @param left Solving for the left boundary of the realized productivity.
#' @param right Solving for the right boundary of the realized productivity.
#' @return A forestData class in which a data.frame with realized productivity parameters is added.
#' @examples
#' \donttest{
#' # Load sample data
#' data("forestData")
#'
#' # Build a model based on the forestData and return a forestData class object
#' forestData <- class.plot(forestData,model="Richards",
#'                          interval=5,number=5,maxiter=1000,
#'                          H_start=c(a=20,b=0.05,c=1.0))
#'
#' # Calculate the realized productivity of the forestData object
#' forestData <- realized.productivity(forestData,left=0.05,right=100)
#' }
#' @export realized.productivity

realized.productivity <- function(forestData, left=0.05, right=100) {
  if(!inherits(forestData, "forestData")){
    stop("Only data in forestData format is available!")
  }
  if(!inherits(forestData$BAmodel,"modelobj")){
    stop("BA model is missing!")
  }
  if(!inherits(forestData$Biomodel,"modelobj")){
    stop("Bio model is missing!")
  }
  data <- forestData$Input
  data_BA <- forestData$output$BA
  data_V <- forestData$output$Bio
  data <- arrange(data,code)
  code.level <- unique(data$code)
  output <- data.frame()
  for (code in code.level) {
    N <- 2+max(forestData$Input$LASTGROUP)
    Nrow <- c(data_BA$code == code)
    parameterBA <- list(b1 = data_BA[Nrow,2:(N-1)] %>%
                          as.numeric(.),
                        b2 = data_BA[Nrow,N],
                        b3 = data_BA[Nrow,N+1],
                        b4 = data_BA[Nrow,(N+2):(2*N-1)] %>%
                          as.numeric(.),
                        S0_BA = data_BA[Nrow,2*N]
    )

    parameterV <- list(v1 = data_V[Nrow,2:(N-1)] %>%
                         as.numeric(.),
                       v2 = data_V[Nrow,N],
                       v3 = data_V[Nrow,N+1],
                       v4 = data_V[Nrow,(N+2):(2*N-1)] %>%
                         as.numeric(.),
                       S0_V = data_V[Nrow,2*N]
    )
    data <- data[data$code == code,]
    inputData <- data.frame(AGE = data$AGE, S = data$S,data$LASTGROUP)
    BAVIGet <- function(data){
      AGE = data[1]
      S = data[2]
      LASTGROUP = data[3]
      temp <- BAVI(AGE,S,LASTGROUP,parameterBA,parameterV,left,right)
    }
    output <- apply(inputData,1,BAVIGet)
    output <- as.data.frame(t(sapply(output, "[", i = 1:max(sapply(output, length)))))
    data$BAI <- output[,1] %>% as.numeric(.)
    data$VI <- output[,2] %>% as.numeric(.)
  }
  data$BAI[data$BAI < 0] <- 0
  data$VI[data$VI < 0] <- 0
  forestData$realized.productivity <- data
  return(forestData)
}
