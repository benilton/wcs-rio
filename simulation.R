# Load necessary libraries
library(dplyr)
library(MASS)
library(MAST)
library(ROCR)
library(pROC)
library(ggplot2)

# Simulation parameters
set.seed(123)
n_cells <- 200  # Number of cells per group
n_genes <- 33000  # Number of genes
group <- rep(c("A", "B"), each = n_cells)

# Generate synthetic data
generate_data <- function(n_cells, n_genes, diff_expr_genes, effect_size) {
  data <- matrix(rnbinom(2*n_cells * n_genes, size=1, mu=10), nrow=n_genes)
  diff_genes <- sample(n_genes, diff_expr_genes)
  tmp <- matrix(rnbinom(n_cells * diff_expr_genes, size=1, mu=10 + effect_size), nrow = diff_expr_genes)
  data[diff_genes, (n_cells + 1):(2 * n_cells)] <- tmp
  return(list(data=data, degs = diff_genes))
}

# Perform tests
perform_tests <- function(data, group) {
  results <- data.frame(gene = 1:nrow(data))
  
  # Wilcoxon rank sum test
  wilcox_p <- apply(data, 1, function(x) wilcox.test(x ~ group)$p.value)
  results$wilcox_p <- wilcox_p
  
  # T-test
  ttest_p <- apply(data, 1, function(x) t.test(x ~ group)$p.value)
  results$ttest_p <- ttest_p
  
  # Negative binomial test
  nb_p <- apply(data, 1, function(x) {
    fit <- glm.nb(x ~ group)
    summary(fit)$coefficients[2, 4]
  })
  results$nb_p <- nb_p
  
  # MAST
  exprs <- data
  sca <- FromMatrix(exprsArray = log(1+exprs), cData = data.frame(group = group))
  zlmCond <- zlm(~group, sca)
  mast_p <- summary(zlmCond, doLRT='groupB')$datatable
  mast_p <- mast_p[mast_p$contrast=='groupB' & mast_p$component=='H', 'Pr(>Chisq)']
  results$mast_p <- mast_p
  
  return(results)
}

# Simulate data and perform tests
sim_data <- generate_data(n_cells, n_genes, diff_expr_genes = 1000, effect_size = 5)
test_results <- perform_tests(sim_data$data, group)

fdr_results <- apply(test_results[,-1], 2, p.adjust, method = "fdr")

# Evaluate power
alpha <- 0.05

## DEGs
rbind(pval = round(colMeans(test_results[sim_data$degs, -1] < alpha), 2),
      fdr = round(colMeans(fdr_results[sim_data$degs,] < alpha), 2))

## Not DEGs
rbind(pval = round(colMeans(test_results[-sim_data$degs, -1] < alpha), 2),
      fdr = round(colMeans(fdr_results[-sim_data$degs,] < alpha), 2))


# Plot results
results_power_df <- data.frame(Test = names(results_power), Power = results_power)
ggplot(results_power_df, aes(x = Test, y = Power)) +
  geom_bar(stat = "identity") +
  ylim(0, 1) +
  labs(title = "Statistical Power of Different Tests",
       x = "Test",
       y = "Power") +
  theme_minimal()

# Display power values
print(results_power)
