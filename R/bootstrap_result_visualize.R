
#' Bootstrap_P_Barplot
#' @description This bar plot shows the -log2(p value) for bootstrap result,
#' using the ggplot packages
#'
#' @param p_results vector p results
#' @param p_names names for p
#' @param title The title names of the plot
#' @param figurenames The filename and address of the output plot,
#' default is "test_barplot.pdf".IF figurenames= NULL, only plot the figure
#' and have not pdf figure.
#' @param width figure width, default is 5
#' @param height figure height,default is 7
#' @param do_plot whether to plot the plot.
#'
#' @return A figure of barplot in pdf format, red color is significant.
#' @export
#'
#' @examples
#' library(scPagwas)
#' load(system.file("extdata", "Pagwas_data.RData", package = "scPagwas"))
#'
#' Bootstrap_P_Barplot(
#'   p_results = Pagwas_data@misc$bootstrap_results$bp_value[-1],
#'   p_names = rownames(Pagwas_data@misc$bootstrap_results)[-1],
#'   width = 5,
#'   height = 7,
#'   do_plot = TRUE,
#'   title = "Test"
#' )
#' @author Chunyu Deng
#' @aliases Bootstrap_P_Barplot
#' @keywords Bootstrap_P_Barplot, plot the Barplot for scPagwas
#' bootstrap celltypes result.

Bootstrap_P_Barplot <- function(p_results,
                                p_names,
                                title = "Test scPagwas",
                                figurenames = NULL,
                                width = 5,
                                height = 7,
                                do_plot = TRUE) {
  logp <- -log2(p_results)
  sig <- rep("b", length(p_results))
  sig[which(p_results < 0.05)] <- "a"
  gg <- data.frame(logp, sig, p_names)
  if (sum(p_results < 0.05) > 0) {
    p1 <- ggplot2::ggplot(gg, aes(
      x = stats::reorder(p_names, logp),
      y = logp,
      fill = sig
    )) +
      geom_bar(position = "dodge", stat = "identity") +
      theme_classic() +
      labs(x = "", y = "-log2(p)", title = title) +
      coord_flip() +
      # scale_fill_discrete()+
      geom_hline(aes(yintercept = 4.321),
        colour = "#990000",
        linetype = "dashed"
      ) +
      scale_fill_manual(values = c("#BB6464", "#C3DBD9")) +
      theme(legend.position = "none")
  } else {
    p1 <- ggplot2::ggplot(
      gg,
      aes(
        x = stats::reorder(p_names, logp),
        y = logp
      )
    ) +
      geom_bar(position = "dodge", stat = "identity", color = "#C3DBD9") +
      theme_classic() +
      labs(x = "", y = "-log2(p)", title = title) +
      coord_flip() +
      theme(legend.position = "none")
  }
  if (do_plot) print(p1)

  if (!is.null(figurenames)) {
    grDevices::pdf(figurenames, width = width, height = height)
    print(p1)
    grDevices::dev.off()
  }
}


#' Bootstrap_estimate_Plot
#' @description This forest plot shows the correct estimate values and
#' 95% CI for different celltyppes, using the ggplot packages
#' @param bootstrap_results result list of Pagwas from 
#' Pagwas$bootstrap_results or Pagwas@misc$bootstrap_results
#' @param figurenames The filename and address of the output plot,
#' default is "test_forest.pdf".IF figurenames= NULL,
#' only plot the figure and have not pdf figure.
#' @param width figure width
#' @param height figure height
#' @param do_plot whether to plot the plot.
#'
#' @return A forest plot with the table of p values
#' @export
#'
#' @examples
#' library(scPagwas)
#' load(system.file("extdata", "Pagwas_data.RData", package = "scPagwas"))
#'
#' Bootstrap_estimate_Plot(
#'   Pagwas = Pagwas_data,
#'   width = 9,
#'   height = 7,
#'   do_plot = TRUE
#' )
#' @author Chunyu Deng
#' @aliases Bootstrap_estimate_Plot
#' @keywords Bootstrap_estimate_Plot, plot the forest for scPagwas
#' bootstrap celltypes result.
Bootstrap_estimate_Plot <- function(bootstrap_results,
                                    figurenames = NULL,
                                    width = 9,
                                    height = 7,
                                    do_plot = F) {
  Index <- estimate <- lower <- upper <- label <- Pvalue <- NULL
  bootstrap_results <- bootstrap_results[-1, c(
    "bp_value",
    "bias_corrected_estimate",
    "CI_lo",
    "CI_hi"
  )]
  bootstrap_results <- bootstrap_results[order(
    bootstrap_results$bias_corrected_estimate,
    decreasing = T
  ), ]

  dat <- data.frame(
    Index = seq_len(nrow(bootstrap_results)),
    label = rownames(bootstrap_results),
    estimate = bootstrap_results$bias_corrected_estimate,
    lower = bootstrap_results$CI_lo,
    upper = bootstrap_results$CI_hi,
    #转化为科学计数法
    Pvalue = bootstrap_results$bp_value
  )

  plot1 <- ggplot2::ggplot(dat, aes(
    y = Index,
    x = estimate
  )) +
    geom_errorbarh(aes(
      xmin = lower,
      xmax = upper
    ),
    color = "#6D8299",
    height = 0.25
    ) +
    geom_point(
      shape = 18,
      size = 5,
      color = "#D57E7E"
    ) +
    geom_vline(
      xintercept = 0,
      color = "#444444",
      linetype = "dashed",
      cex = 1,
      alpha = 0.5
    ) +
    scale_y_continuous(
      name = "", breaks = seq_len(nrow(dat)),
      labels = dat$label,
      trans = "reverse"
    ) +
    xlab("bias_corrected_estimate (95% CI)") +
    ylab(" ") +
    theme_bw() +
    theme(
      panel.border = element_blank(),
      panel.background = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.line = element_line(colour = "black"),
      axis.text.y = element_text(size = 12, colour = "black"),
      axis.text.x.bottom = element_text(size = 12, colour = "black"),
      axis.title.x = element_text(size = 12, colour = "black")
    )
  # plot1

  table_base <- ggplot2::ggplot(dat, aes(y = label)) +
    ylab(NULL) +
    xlab("  ") +
    theme(
      plot.title = element_text(hjust = 0.5, size = 12),
      axis.text.x = element_text(
        color = "white",
        hjust = -3,
        size = 25
      ), ## This is used to help with alignment
      axis.line = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks = element_blank(),
      axis.title.y = element_blank(),
      legend.position = "none",
      panel.background = element_blank(),
      panel.border = element_blank(),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      plot.background = element_blank()
    )

  ## OR point estimate table
  tab1 <- table_base +
    labs(title = "space") +
    geom_text(aes(
      y = rev(Index), x = 1,
      label = sprintf("%.3f", round(Pvalue, digits = 3))
    ),
    size = 4
    ) + ## decimal places
    ggtitle("Pvalue")

  lay <- matrix(c(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3), nrow = 1)
  plot2 <- gridExtra::grid.arrange(plot1, tab1, layout_matrix = lay)
  if (do_plot) print(plot2)
  ## save the pdf figure
  if (!is.null(figurenames)) {
    grDevices::pdf(file = figurenames, width = width, height = height)
    print(plot2)
    grDevices::dev.off()
  }
}
