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

df <- read.csv("simulation/results/results.csv")
df <- df %>%
    group_by(p, graph, method) %>%
    summarise(
        across(c(FDR, FPR, TPR, SHD),
            mean_sd,
            digits = 2, denote_sd = "paren"
        )
    )

kable(df) %>% kable_styling(latex_options = "striped")