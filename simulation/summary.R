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

df1 <- read.csv("simulation/result/RFCI.csv")
df2 <- read.csv("simulation/result/CAM.csv")
df3 <- read.csv("simulation/result/LRpS-GES.csv")
df4 <- read.csv("simulation/result/LRpS-GES-0.csv")
df <- rbind(df1, df2, df3, df4)


df <- df %>%
    group_by(p, graph, method) %>%
    summarise(
        across(c(FDR, FPR, TPR, SHD),
            mean_sd,
            digits = 2, denote_sd = "paren"
        )
    )

kable(df) %>% kable_styling(latex_options = "striped")