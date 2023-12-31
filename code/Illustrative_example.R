library(mgcv)
library(tidyverse)
library(reshape2)
library(ggpubr)
library(scales)
library(broom)
library(knitr)
library(parallel)
library(fitdistrplus)
library(metRology)

# Model functions
null_model <- function(df){
  with(df, bam(RelInt ~ s(Fraction, k = nlevels(df$Fraction)) + factor(Experiment) + factor(Replicate),
               data = df,
               method = "REML",
               family = gaussian(),
               robust = TRUE))
}

alt_model <- function(df){
  with(df, bam(RelInt ~ s(Fraction, k = nlevels(df$Fraction), by=factor(Experiment)) + factor(Replicate),
               data = df,
               method = "REML",
               family = gaussian(),
               robust = TRUE))
}

# Extract residuals from the combined model
DDX42_null_model <- null_model(DDX42)
DDX42_alt_model <- alt_model(DDX42)

null_residuals <- residuals(combined_model)
# Quantify the differences between model fits with the  likelihood ratio test
DDX_LRT <- anova(DDX42_null_model, DDX42_alt_model, test="LRT")
DDX_LRT

# Add fitted values and residuals from each model to the data.
DDX42<- 
  DDX42 %>% 
  mutate(Fitted_null = fitted(DDX42_null_model),
         Residuals_null = residuals(DDX42_null_model),
         Fitted_alt = fitted(DDX42_alt_model),
         Residuals_alt = residuals(DDX42_alt_model))

# We will now visualize the models.
DDX42_null_plot <- DDX42_plot +
  geom_line(data = distinct(DDX42, Fraction, Fitted_null),
            aes(x = Fraction, y = Fitted_null, group=1),
            linewidth = 1.2, alpha = 0.6)+
  annotate(geom = "text", x = 6, y = 0.25, label = "RSS = 0.0259", 
           size = 5)

DDX42_alt_plot <- DDX42_plot +
  geom_line(data = distinct(DDX42, Fraction, Experiment, Fitted_alt),
            aes(x = Fraction, y = Fitted_alt, group=Experiment,
                color = Experiment),linewidth = 1.2, alpha = 0.7)+
  annotate(geom = "text", x = 6, y = 0.25, label = "RSS = 0.0092", 
           size = 5)

# For a better visual comparison we combine the model plots (corresponding to Fig.X):
ggarrange(DDX42_null_plot, DDX42_alt_plot, ncol = 2, common.legend = TRUE,
          labels = c("Null model", "Alternative model"), label.x = 0.2)
