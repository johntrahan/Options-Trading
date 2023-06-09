library(tidyverse)

# Define Monte Carlo Pricer class
MonteCarloPricer <- function(spot, strike, maturity, r, sigma, n_steps, n_paths, optionType) {
  
  # Class initialization
  self = list(
    strike = strike,
    spot = spot,
    sigma = sigma,
    r = r,
    maturity = maturity,
    n_paths = n_paths,
    n_steps = n_steps,
    optionType = optionType
  )
  
  # Method to generate the random paths
  self$generatePaths = function() {
    dt <- self$maturity / self$n_steps
    ito <- (self$r - self$sigma^2/2) * dt
    sqvar <- self$sigma * sqrt(dt)
    innovation <- matrix(rnorm(self$n_steps * self$n_paths), nrow = self$n_steps)
    paths <- matrix(self$spot, nrow = self$n_steps + 1, ncol = self$n_paths)
    for (i in 2:(self$n_steps + 1)) {
      paths[i,] <- paths[i-1,] * exp(ito + sqvar * innovation[i-1,])
    }
    paths <- paths[-1,]
    return(paths)
  }
  
  # Method to visualize the paths generated by the generatePaths method
  library(ggplot2)
  
  self$visualizePaths = function(paths) {
    df <- data.frame(paths)
    colnames(df) <- paste0("Path", 1:self$n_paths)
    df$TimeSteps <- 1:nrow(df)
    df <- tidyr::gather(df, key = "Path", value = "StockPrice", -TimeSteps)
    
    ggplot(df, aes(x = TimeSteps, y = StockPrice, color = Path)) +
      geom_line() +
      geom_hline(yintercept = self$strike) +
      ggtitle(paste0("Simulated stock prices with ", self$n_steps,
                     " steps and ", self$n_paths, " price paths\n",
                     self$optionType, " option with strike price of ", self$strike)) +
      xlab("Time Steps") +
      ylab("Stock Price")
  }
  
  # Payoff function depending on the contract type, call or put
  payoff <- function(paths) {
    if (self$optionType == "call") {
      return(pmax(paths[nrow(paths), ] - self$strike, 0))
    } else if (self$optionType == "put") {
      return(pmax(self$strike - paths[nrow(paths), ], 0))
    } else {
      return(0)
    }
  }
  
  # Method to discount the paths price
  discountedExpectation <- function(payoffs) {
    return(mean(payoffs) * exp(-self$r * self$maturity))
  }
  
  # Return list of methods
  return(list(generatePaths = self$generatePaths,
              visualizePaths = self$visualizePaths,
              payoff = payoff,
              discountedExpectation = discountedExpectation))
}

# Define input parameters
S <- 100   # Spot price
K <- 105   # Strike price
T <- 1/2   # Time to maturity in years
r <- 0.05  # Risk-free rate
sigma <- 0.2 # Volatility
steps <- 100 # Number of steps
N <- 500 # Number of paths
optionType <- "call" # Option contract type

# Initialize the Monte Carlo Pricer
pricer <- MonteCarloPricer(S, K, T, r, sigma, steps, N, optionType)

# Generate random paths and visualize them
paths <- pricer$generatePaths()
pricer$visualizePaths(paths)

# Calculate the discounted expectation of the option payoff
payoffs <- pricer$payoff(paths)
cat("Expected Payout is",pricer$discountedExpectation(payoffs))

#make sure to find volatility, either implied volatility or 
#use past year's daily change sd * sqrt(252)
#To avoid the first number from yahoo finance example:
#NEE = NEE %>%
#select(Date,Close) %>%
  #mutate(daily_change = (Close - lag(Close))/lag(Close),
         #percentage_change = (Close - lag(Close))/lag(Close)*100)

#NEE %>%
  #filter(row_number() != 1) %>%
  #summarize(volatility = sd(daily_change)*sqrt(252))