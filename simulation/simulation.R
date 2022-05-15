
packages <- c(
    "tidyr",
    "progress",
    "CAM",
    "lrpsadmm",
    "pcalg",
    "bnlearn",
    "mvtnorm"
)
invisible(lapply(packages, library, character.only = TRUE))

simulator <- function(p_seq = c(25),
                      graphs_seq = c("random", "hub"),
                      n_seq = c(500, 1000, 1500),
                      methods_seq = c("CAM", "RFCI", "LRpS-GES"),
                      num_simulation = 100, seed = 1110) {
    set.seed(seed)

    source_files <- list.files("R/", "*.R$")
    invisible(lapply(paste0("R/", source_files), source))

    source_files <- list.files("R/methods/", "*.R$")
    invisible(lapply(paste0("R/methods/", source_files), source))

    source_files <- list.files("R/methods/utils/", "*.R$")
    invisible(lapply(paste0("R/methods/utils/", source_files), source))

    res_dir <- "simulation/result"
    if (!dir.exists(res_dir)) dir.create(res_dir)

    result_file <- "cam_ges_fci.csv"
    if (file.exists(result_file)) file.remove(result_file)

    result <- c()

    for (p in p_seq) {
        for (graph_type in graphs_seq) {
            u <- graph_generator(p, graph_type)
            for (n in n_seq) {
                cat(sprintf(
                    "p = %d, graph_type = %s, n = %d\n",
                    p, graph_type, n
                ))

                pb <- progress_bar$new(
                    format = paste0(
                        "[:bar] ",
                        ":percent ",
                        "[Elapse time: :elapsedfull] ",
                        "[Time left: :eta]"
                    ),
                    total = num_simulation,
                    complete = "=",
                    incomplete = "-",
                    current = ">",
                    clear = TRUE,
                    width = 100
                )

                for (sim in seq_len(num_simulation)) {
                    pb$tick()
                    y <- data_generator(u, n)$y

                    for (method in methods_seq) {

                        # CAM, LRpS-GES, and RFCI
                        out <- causal_discovery(
                            y = y,
                            method = method
                        )
                        res <- metrics(u, out$u)
                        
                        FDR <- res$FDR
                        FPR <- res$FPR
                        TPR <- res$TPR
                        SHD <- res$SHD

                        result <- rbind(
                            result,
                            c(
                                p,
                                graph_type,
                                n,
                                sim,
                                method,
                                FDR,
                                FPR,
                                TPR,
                                SHD
                            )
                        )
                        colnames(result) <- c(
                            "p",
                            "graph",
                            "n",
                            "sim",
                            "method",
                            "FDR",
                            "FPR",
                            "TPR",
                            "SHD"
                        )
                        write.csv(result,
                            sprintf("%s/%s", res_dir, result_file),
                            row.names = FALSE
                        )
                    }
                }
                cat("\n")
            }
        }
    }
}

simulator()
