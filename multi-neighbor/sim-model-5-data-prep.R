# Author: Matthew Phelps
#Desc: Prepare data from JAGS for simulations
source("Data-3-combine quarters.R")


# LOAD & PREP DATA ---------------------------------------------------------------

load(file = "Data/Rdata/multi-model1-data-prep.Rdata")
N_i_daily <- N_pop



# OBSERVED INCIDENCE DATA -------------------------------------------------
# Data into format for ggplot
addDay <- function(x){
  x1 <- data.frame(x)
  x1$day <- 1:112
  x1
}
tidyReps <- function(x) x %>% gather(quarter, I_new,1:9)

I_reps_plot <- I_reps %>%
  lapply(addDay) %>%
  lapply(tidyReps)


nameReplace <- function(x){
  x$quarter[x$quarter=="St..Annae.Oester"] <- "St. Annae Oester"
  x$quarter[x$quarter=="St..Annae.Vester"] <- "St. Annae Vester"
  x
}
I_reps_plot <- lapply(I_reps_plot, nameReplace)


# Turn list into one long df
for (i in 1:length(I_reps_plot)){
  I_reps_plot[[i]]$rep <- paste(i)
}


I_reps_plot <- do.call(rbind.data.frame, I_reps_plot)

# INITIALIZE EMPTY DF -----------------------------------------------------
N_it <- matrix(NA, Nquarter, 1)
N_it[, 1] <- unique(combined$est.pop.1853)

# SAVE --------------------------------------------------------------------
# If in future we sample from posterior, keep "y" object that I remove below 
rm(N_i_daily, i, addDay, nameReplace, tidyReps)


