# Model 6 - Hydraulic connections. IF quarters are connected, THRN beta = beta * eta,
# ELSE beta = beta
# *non-reported cases are not infectious

model {
  # Gamma - rate of recovery from infectious state
  gamma_b ~ dexp(5)
  
  # Force of infection hyperprior
  # One hyperprior for entire city
  mu ~ dnorm(0, 0.001)
  tau ~ dgamma(0.001, 0.001)
  
  # Effect of hydraulic connection
  log_eta ~ dnorm(0, 0.001)
  eta <- exp(log_eta)
  
  # Phi - under reporting fraction
  logit_phi ~dnorm(0, 0.001)
  phi <- 1 / (1 + exp(-logit_phi))
  
  # Create force of infection matrix and populate 1st time-step from data
  for (i in 1:Nquarter){
    # First time-step
    S_it_daily[1, i] <- N_i_daily[i];
    
    I_prev[1, i] <- ifelse(i==5 || i == 8 || i == 9,1,0)
    
    for (j in 1:Nquarter){
      # Betas - force of infection (foi). Diagnols are internal foi,
      # off-diag are between-neighborhood foi.
      # For each, draw log_beta from normal with hyperprior params
      log_beta[i, j] ~ dnorm(mu, tau);

      # If there is a water-pipe connection b/w neighborhoods, foi = foi + eta
      beta[i, j] <- exp(log_beta[i, j])
      foi[i, j] <- ifelse(water[i, j]==1, eta + beta[i, j], beta[i, j]);
    } 
  }
  
  
  # Lambda, I, S, & R
  for (t in 1:(Nsteps-1)){
    for (i in 1:Nquarter){
      lambdaI[t, i] <-  (S_it_daily[t, i]  / N_i_daily[i]) * (sum(foi[, i] * (I_prev[t, ])))
      lambdaR[t, i] <- I_prev[t, i] * gamma_b
      R_temp[t, i] <- lambdaR[t, i]
      R_new[t, i] <- min(I_prev[t, i], R_temp[t, i])
      I_prev[t+1, i] <- (I_prev[t, i] + I_incidence[t, i]/phi - R_new[t, i])
      S_it_daily[t+1, i] <- S_it_daily[t, i] - (I_incidence[t, i] / phi)
    }
  }
  
  # Likelihood function
  for (t in 1:(Nsteps-1)){
    for (i in 1:Nquarter){
      I_incidence[t+1, i] ~ dpois(lambdaI[t, i] * phi)
      # This log-density function is not documented in the JAGS manual. Found via
      # the 6th response on this forum: https://goo.gl/UisKKW
      llsim [t + 1, i] <- logdensity.pois(I_incidence[t + 1, i], lambdaI[t, i])
      lik[t + 1, i] <- exp(llsim[t + 1, i])
    }
  }
  #data# Nsteps
  #data# N_i_daily
  #data# I_incidence
  #data# Nquarter
  #data# water
  
  #inits# inits1
  #inits# inits2
  #inits# inits3
  #inits# inits4
}
