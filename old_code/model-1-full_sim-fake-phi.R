# Author: Matthew Phelps
#Desc: Full model from Initial time-step. Model 0_3
# Dependicies: Data 1, Data 2, 5_GLM_data_reshape, 8c_JAGS


# Intro -------------------------------------------------------------------
graphics.off()
ifelse(grepl("wrz741", getwd()),
       wd.path <- "C:\\Users\\wrz741\\Google Drive\\Copenhagen\\DK Cholera\\CPH",
       wd.path <-"/Users/Matthew/Google Drive/Copenhagen/DK Cholera/CPH")
setwd(wd.path)
rm(list = ls())

library(ggplot2)
library(reshape)
require(grid)
library(ggiraph)

# LOAD data ---------------------------------------------------------------

load(file = 'Data/Rdata/model-1-sim_data.Rdata')

set.seed(13)

loops <- 1000
duration <- 5 # In days. "1-2 weeks" from DOI:  10.1038/nrmicro2204
gamma <- 1/duration
model_1_obs <- as.data.frame(I_it_daily)
model_1_obs$day_index <- 1:Nsteps

#  Point Eestimate MODEL FROM INITIAL STATE -------------------------------------

loops <- loops
R_new <- data.frame(matrix(data =  NA, nrow = loops, ncol = Nsteps))
Lambda_sim <- data.frame(matrix(data = NA, nrow = loops, ncol = Nsteps))
LambdaR <- data.frame(matrix(data = NA, nrow = loops, ncol = Nsteps))
I_new_full <- data.frame(matrix(data = NA, nrow = loops, ncol = Nsteps))
S_temp <- data.frame(matrix(data = NA, nrow = loops, ncol = Nsteps))
I_sim_mat <- data.frame(matrix(data = NA, nrow = loops, ncol = Nsteps))
S_sim_mat <- data.frame(matrix(data = NA, nrow = loops, ncol = Nsteps))

# Starting (t = 0) values:
S_sim_mat[, 1] <- S_it_est[1]
I_sim_mat[, 1] <- I_it_daily[1]

# Simluate:
ptm <- proc.time()
set.seed(13)
for (z in 1:loops){
  for (t in 1:(Nsteps-1)){
    Lambda_sim[z, t] <- S_sim_mat[z, t] / N_i_daily * (beta_pe[1] *(I_sim_mat[z, t]))
    LambdaR[z, t] <- I_sim_mat[z, t] * gamma
    R_new[z, t] <- rpois(1, LambdaR[z, t])
    I_new_full[z, t] <- rpois(1, (Lambda_sim[z, t] ) )
    I_sim_mat[z, t + 1] <- max(0, (I_new_full[z, t] + I_sim_mat[z, t] - R_new[z, t]))
    S_temp[z, t] <- (S_sim_mat[z, t]) -    (I_new_full[z, t]) / (phi_pe[1])
    S_sim_mat[z, t + 1] <- max(0, S_temp[z, t])
  }
}
proc.time()- ptm

# SAVE for likelhood calculation
I_fake_phi <- I_est_pe_list
save(I_fake_phi, file = 'data\\Rdata\\I_fake_phi.Rdata')


# PLOT FULL ---------------------------------------------------------------
model_1_full <- as.data.frame(t(I_new_full))
model_1_full$day_index <- 1:Nsteps
model_1_full_melt <- melt(model_1_full, id.vars = 'day_index')


no_loops <- as.character(loops)
sub_title <- paste("No. simulations = ", no_loops, "")

model_1_full_sim_plot <- ggplot() +
  geom_line(data = model_1_full_melt,
            aes(x = day_index, y = value, group = variable),
            color = 'darkgreen', alpha = 0.02) +
  geom_line (data = model_1_obs,
             aes(x = day_index, y = I_it_daily),
             color = 'darkred', alpha = 0.5, size = 1.2) +
  theme_minimal()+
  ylab("People") +
  xlab("Day index") +
  theme(plot.title = element_text(size = 22, face="bold"),
        axis.text.y = element_text(size = 15),
        axis.text.x = element_text(size = 15),
        axis.title.x = element_text(size = 21, face = "bold"),
        axis.title.y = element_text(size = 21, face = "bold", vjust = 1.4))+
  ggtitle(bquote(atop("St.Annae V. Incidence", atop(italic(.(sub_title)), "")))) #http://go
model_1_full_sim_plot
#
# system.time(
# ggsave(model_1_full_sim_plot, 
#        file = 'C:\\Users\\wrz741\\Google Drive\\Copenhagen\\DK Cholera\\CPH\\Output\\Simulations\\model-1-full-sim-fake-phi.pdf',
#        width=15, height=9,
#        units = 'in')
# )



# STEP AHEAD SIMULATION ---------------------------------------------------

loops <- loops
R_i <- seq(from = 0, to = 0, length.out = length(I_it_daily))
R_new <- data.frame(matrix(data =  NA, nrow = loops, ncol = Nsteps))
Lambda_est_pe <- data.frame(matrix(data = NA, nrow = loops, ncol = Nsteps))
LambdaR <- data.frame(matrix(data = NA, nrow = loops, ncol = Nsteps))
I_new <- data.frame(matrix(data = NA, nrow = loops, ncol = Nsteps))
S_temp <- data.frame(matrix(data = NA, nrow = loops, ncol = Nsteps))
I_plus1_mat <- data.frame(matrix(data = NA, nrow = loops, ncol = Nsteps))
S_plus1_mat <- data.frame(matrix(data = NA, nrow = loops, ncol = Nsteps))
S_plus1_mat[, 1] <- N_i_daily
I_plus1_mat[, 1] <- 0
R_new[, 1] <- 0
I_new[, 1] <- 0
set.seed(13)
for (z in 1:loops){

  for (t in 1:(Nsteps-1)){
    # if(z == 106 && t == 64)

    Lambda_est_pe[z, t] <- S_plus1_mat[z, t] / N_i_daily * (beta_pe[1] *(I_plus1_mat[z, t]))
    LambdaR[z, t] <- I_plus1_mat[z, t] * gamma
    R_new[z, t] <- rpois(1, LambdaR[z, t])
    I_new[z, t] <- rpois(1, (Lambda_est_pe[z, t] ) )
    I_plus1_mat[z, t + 1] <- max(0, (I_it_daily[15] + I_plus1_mat[z, t] - R_new[z, t]))
    S_temp[z, t] <- (S_plus1_mat[z, t]) -    (I_it_daily[t]) / (phi_pe[1])
    S_plus1_mat[z, t + 1] <- max(0, S_temp[z, t])
  }
}
I_plus1_mat[106,]
I_new[106,]
# SAVE for likelhood calculation
I_fake_plus1_phi <- I_new
save(I_fake_plus1_phi, file = 'data\\Rdata\\I_fake_plus1_phi.Rdata')


# PLOTTING ----------------------------------------------------------------
model_1_tplus1 <- as.data.frame(t(I_new))
model_1_tplus1$day_index <- 1:Nsteps
model_1_tplus1_melt <- melt(model_1_tplus1, id.vars = 'day_index')



no_loops <- as.character(loops)
sub_title <- paste("No. simulations = ", no_loops, "")

model_1_tplus1_plot <- ggplot() +
  geom_line(data = model_1_tplus1_melt,
            aes(x = day_index, y = value, group = variable),
            color = 'darkgreen', alpha = 0.05) +
  geom_line(data = model_1_obs,
            aes(x = day_index, y = I_it_daily),
            color = 'darkred', alpha = 0.5, size = 1.3) +
  theme_minimal()+
  ylab("People") +
  xlab("Day index") + 
  theme(plot.title = element_text(size = 22, face="bold"),
        axis.text.y = element_text(size = 15),
        axis.text.x = element_text(size = 15),
        axis.title.x = element_text(size = 21, face = "bold"),
        axis.title.y = element_text(size = 21, face = "bold", vjust = 1.4))+
  ggtitle(bquote(atop("St.Annae V. t + 1", atop(italic(.(sub_title)), "")))) #http://go
model_1_tplus1_plot

system.time(ggsave(model_1_tplus1_plot, 
                   file = 'C:\\Users\\wrz741\\Google Drive\\Copenhagen\\DK Cholera\\CPH\\Output\\Simulations\\model_1_tplus1-fake-phi.pdf',
                   width=15, height=9,
                   units = 'in')
)

