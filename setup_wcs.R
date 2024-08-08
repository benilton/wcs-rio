## Setup script for WCS Course in Rio
## By Benilton Carvalho

## https://stackoverflow.com/questions/70025153/how-to-access-the-shell-in-google-colab-when-running-the-r-kernel
shell_call <- function(command, ...) {
  result <- system(command, intern = TRUE, ...)
  cat(paste0(result, collapse = "\n"))
}

# Install curl if missing
shell_call("apt update -qq")
shell_call("apt install -y --no-install-recommends curl ca-certificates git")

## Setup bioc2u and r2u
shell_call("curl https://raw.githubusercontent.com/Bioconductor/bioc2u/devel/apt_setup.sh | sudo bash")
bspm::enable()
options(bspm.version.check=FALSE)

## Install the R packages
cranPkgs2Install = c("BiocManager", "ggpubr", "Seurat", "cowplot",
                     "Rtsne", "hdf5r", "clustree", "devtools")
install.packages(cranPkgs2Install, ask=FALSE, update=TRUE, quietly=TRUE)

## Install the Bioconductor packages
biocPkgs2Install = c("clusterProfiler", "preprocessCore", "rols",
                     "scDblFinder","clusterExperiment", "SingleR",
                     "celldex", "org.Hs.eg.db")
BiocManager::install(biocPkgs2Install, ask=FALSE, update=TRUE, quietly=TRUE)

## Install presto to save time with Wilcoxon Rank Sum Test in Seurat
devtools::install_github('immunogenomics/presto')
