# Author: Matthew Phelps
#Desc: Prepare data for model simulation based on posterior
# Dependicies: Data 1, Data 2, 5_GLM_data_reshape, 8c_JAGS


# Intro -------------------------------------------------------------------

graphics.off()
mac <- "/Users/Matthew/Google Drive/Copenhagen/DK Cholera/CPH"
pc <- "C:\\Users\\wrz741\\Google Drive\\Copenhagen\\DK Cholera\\CPH"
setwd(pc)
rm(list = ls())




# LOAD & PREP DATA ---------------------------------------------------------------


load(file = "data\\Rdata\\quarter_combined.Rdata")
load(file = 'data\\Rdata\\beta_summary_1_1.Rdata')
load(file = 'data\\Rdata\\phi_summary_1_1.Rdata')
load(file = 'data\\Rdata\\model1_1_jags.Rdata')
JagsOutput <- model1_1_jags
rm(model1_1_jags)


# INITIALIZE EMPTY DF -----------------------------------------------------

Nsteps <- 16
quarterID <- as.numeric(combined$quarterID)
Nquarter <- length(table(quarterID))
q_names <-as.data.frame(unique(combined$quarter))


I_it <- matrix(NA, Nquarter, Nsteps-1)
S_it <- matrix(NA, Nquarter, Nsteps-1)

N_it <- matrix(NA, Nquarter, Nsteps)

I_i_t1 <- matrix(0, nrow = Nquarter, ncol = 1)
S_i_t1 <- matrix(0, nrow = Nquarter, ncol = 1)
N_i_t1 <- matrix(0, nrow = Nquarter, ncol = 1)
# Initial state for all quarters
for (i in 1:Nquarter){
  I_i_t1[i, 1] <- (combined$sick.total.week[which(combined$quarterID==i)])[1]
  S_i_t1[i, 1] <- (combined$S[which(combined$quarterID==i)])[1]
}

for(i in 1:Nquarter){
  for (t in 1:Nsteps){
    N_it[i, t] <- (combined$pop1855[which(combined$quarterID==i)])[t]
  }
}

# Bind first time-step of infection data to block of NAs the size of the remaining
# timesteps. These NAs will be overwritten with simulated data 
I_it_est <- (cbind(I_i_t1, I_it))
S_it_est <- (cbind(S_i_t1, S_it))

rm(N_i_t1, S_i_t1 , I_i_t1, I_it, S_it)

# PREPARE MCMC DRAWS ------------------------------------------------------

# Remove 1st 5000K iterations for burn in from each chain
n_iter <- length(JagsOutput$mcmc[[1]][, 1])
n_param <- as.numeric(length(JagsOutput$mcmc[[1]][1, ]))
chain1 <- as.data.frame(JagsOutput$mcmc[[1]][5000:n_iter, ])
chain2 <- as.data.frame(JagsOutput$mcmc[[2]][5000:n_iter, ])
chain3 <- as.data.frame(JagsOutput$mcmc[[3]][5000:n_iter, ])

betas_matrix <- rbind(chain1[, 1:n_param-1, drop = FALSE],
                      chain2[, 1:n_param-1, drop = FALSE],
                      chain3[, 1:n_param-1, drop = FALSE])

# Drop = F is because the "[]" operatore on DF changes a single column into a row vector
# Drop = F stops this from happening
phi_matrix <- rbind(chain1[, 'phi', drop = FALSE],
                    chain2[, 'phi', drop = FALSE],
                    chain3[, 'phi', drop = FALSE])

rm(chain1, chain2, chain3, model1_1_jags)


# 95% HDI for EACH PARAMETER ----------------------------------------------


lower_sample <- round( 0.025 * nrow(betas_matrix), digits = 0)
upper_sample <- nrow(betas_matrix) - lower_sample
sample_size <- length(lower_sample + 1:upper_sample)

# Beta parameter
step2 <- matrix(nrow = sample_size, ncol = n_param-1 )
for (i in 1:(n_param-1)){
  step1 <- betas_matrix[order(betas_matrix[, i]), ]
  step2[, i] <- step1[lower_sample + 1:upper_sample, i]
}
betas_matrix <- as.data.frame(step2)
rm(step1, step2)

# Phi parameter
step1 <- as.data.frame(phi_matrix[order(phi_matrix[, 1]), ])
phi_matrix <- as.data.frame(step1[lower_sample + 1 : upper_sample, 1])
rm(step1)


# POINT ESTIMATES ---------------------------------------------------------

# Beta
step1 <- as.matrix(beta_summary_1_1['Mean'])
beta_pe <- matrix(step1, nrow = Nquarter, ncol = Nquarter, byrow = F)

# Phi
phi_pe <- as.matrix(phi_summary_1_1['Mean'])

save(file = 'data\\Rdata\\model_sim_data.Rdata', list = ls())

