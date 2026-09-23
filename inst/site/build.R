# Build the site. `Rscript build.R docs` writes the tree GitHub Pages serves; with no
# argument it writes dist, which is the one to keep out of version control.
library(muiPersonalWebsite)

args <- commandArgs(trailingOnly = TRUE)
mui_build_site(out_dir = if (length(args)) args[1] else "dist")
