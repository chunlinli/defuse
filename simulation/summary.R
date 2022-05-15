packages <- c(
    "ggplot2",
    "dplyr",
    "tidyr",
    "tidyverse",
    "glue",
    "scales",
    "kableExtra",
    "xtable",
    "qwraps2",
    "knitr"
)
invisible(lapply(packages, library, character.only = TRUE))

df <- read.csv("simulation/result/cam_ges_fci.csv")
fig_dir <- "simulation/fig"
if (!dir.exists(fig_dir)) dir.create(fig_dir)
fig_name <- "cam_ges_fci.png"


df <- df %>%
    group_by(n, graph, method) %>%
    summarise(
        across(c(FDR, FPR, TPR, SHD),
            mean_sd,
            digits = 2, denote_sd = "paren"
        )
    )

kable(df) %>% kable_styling(latex_options = "striped")
