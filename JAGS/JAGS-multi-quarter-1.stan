# 1 beta (citywide) + 1 alpha for city
model {
  # Infectious period is exponential dist
  gamma_b ~ dexp(5)
  
  mu1 ~ dnorm(0, 0.001)
  tau1 ~ dgamma(0.001, 0.001)
  mu2 ~ dnorm(0, 0.001)
  tau2 ~ dgamma(0.001, 0.001)
  
  # 1 Internal force, same for every quarter
  log_beta_1 ~ dnorm(mu1, tau1)
  beta_1 <- exp(log_beta_1)
  
  # 1 external force, same for every quarter
  log_beta_2 ~ dnorm(mu2, tau2)
  beta_2 <- exp(log_beta_2)
  
  # Phi - under reporting fraction (same for all quarters)
  logit_phi ~ dnorm(0, 0.001)
  phi<- exp(logit_phi) / (1 + exp(logit_phi))
  
  for (k in 1:Nquarter){
    # First time-step
    S_it_daily[1, k] <- N_i_daily[k]
    
    # Seed 3 infectious cases 
    I_prev[1, k] <- ifelse(k==5 || k == 8 || k == 9, 1, 0)
    
    for (i in 1:Nquarter){
      
      # Internal transmission on diags, external on off-daigs
      beta[k, i] <- ifelse(k==i, beta_1, beta_2)
    } 
  }
  
  # Lambda, I, S, & R
  for (t in 1:(Nsteps-1)){
    for (i in 1:Nquarter){
      lambdaI[t, i] <-  (S_it_daily[t, i]  / N_i_daily[i]) * (sum(beta[, i] * (I_prev[t, ])))
      R_temp[t, i] <- I_prev[t, i] * gamma_b # track recovered people
      R_new[t, i] <- min(I_prev[t, i], R_temp[t, i]) #enure no negatives
      
      # update prevalance using observed data "I_incidence"
      I_prev[t+1, i] <- (I_prev[t, i] + I_incidence[t, i] / phi - R_new[t, i])
      S_it_daily[t+1, i] <- S_it_daily[t, i] - (I_incidence[t, i] / phi)
    }
  }
  
  # Likelihood function with added tracking of "lik" to allow WAIC calculation
  for (t in 1:(Nsteps-1)){
    for (i in 1:Nquarter){
      I_incidence[t+1, i] ~ dpois(lambdaI[t, i] * phi)
      # This log-density function is not documented in the JAGS manual. Found via
      # the 6th response on this forum: https://goo.gl/UisKKW
      llsim [t + 1, i] <- logdensity.pois(I_incidence[t + 1, i], (lambdaI[t, i]*phi))
      lik[t + 1, i] <- exp(llsim[t + 1, i])
    }
  }
  #data# Nsteps
  #data# N_i_daily
  #data# I_incidence
  #data# Nquarter
}
