
#' plot_bar_positie_nagtive
#'
#' @description Generate barplot of identity group composition
#' Thanks to the SCOPfunctions package
#' https://github.com/CBMR-Single-Cell-Omics-Platform/SCOPfunctions/blob/main/R/plot.R
#' Generate a percentage barplot that shows the composition of each identity
#' (e.g. sample)in terms of groups (e.g. positive and negative cells for scPagwas)
#'
#' @param seurat_obj Seurat object (Seurat ^3.0).
#' @param var_ident the identify variable, character.
#' @param var_group the group variable, character.
#' @param vec_group_colors a vector of colors, named by corresponding group.
#' Length must match number of groups. Character.
#' @param f_color if vec_group_colors is not provided, the user may instead provide a
#' function f_color() that takes as its only argument the number of colors to generate.
#' @param do_plot Whether to plot, logical.
#' @param title NULL to leave out.
#' @param fontsize_title NULL to leave out.
#' @param fontsize_axistitle_x NULL to leave out.
#' @param fontsize_axistitle_y NULL to leave out.
#' @param fontsize_axistext_x NULL to leave out.
#' @param fontsize_axistext_y NULL to leave out.
#' @param fontsize_legendtitle NULL to leave out.
#' @param fontsize_legendtext NULL to leave out.
#' @param width figure width.
#' @param p_thre threshold for p value.
#' @param aspect.ratio default is 1.2.
#' @param output.prefix prefix for output files.
#' @param output.dirs directory for files.
#' @param height figure height.
#'
#' @return a ggplot2 object
#' @export
#'
#' @examples
#' load(system.file("extdata", "Pagwas_data.RData", package = "scPagwas"))
#' plot_bar_positie_nagtive(
#'   seurat_obj = Pagwas_data,
#'   var_ident = "anno",
#'   var_group = "positiveCells",
#'   vec_group_colors = c("#E8D0B3", "#7EB5A6"),
#'   do_plot = FALSE
#' )
#' @aliases plot_bar_positie_nagtive
#' @keywords plot_bar_positie_nagtive, plot bars for the pvalue for cellytpes.

plot_bar_positie_nagtive <- function(seurat_obj,
                                     var_ident,
                                     var_group,
                                     vec_group_colors = NULL,
                                     f_color = grDevices::colorRampPalette(RColorBrewer::brewer.pal(n = 11, name = "RdYlBu")),
                                     do_plot = FALSE,
                                     title = NULL,
                                     p_thre = 0.05,
                                     fontsize_title = 24,
                                     fontsize_axistitle_x = 18,
                                     fontsize_axistitle_y = 18,
                                     fontsize_axistext_x = 12,
                                     fontsize_axistext_y = 12,
                                     fontsize_legendtitle = 12,
                                     fontsize_legendtext = 10,
                                     aspect.ratio = 1.2,
                                     output.prefix = "Test",
                                     output.dirs = NULL,
                                     width = 7,
                                     height = 7) {
  n_ident <- ident <- group <- N <- NULL
  # ===============seurat_obj p==================
  seurat_obj$positiveCells <- rep(0, ncol(seurat_obj))
  seurat_obj$positiveCells[seurat_obj$Random_Correct_BG_adjp < p_thre] <- 1

  # ===============data.table with sums==================
  dt <- data.table(
    "ident" = as.character(seurat_obj@meta.data[[var_ident]]),
    "group" = as.character(seurat_obj@meta.data[[var_group]])
  )
  dt[, n_ident := paste0(ident, " (n=", .N, ")"), by = ident]
  vec_factorLevels <- dt$n_ident[gsub("\\ .*", "", dt$n_ident) %>%
    as.numeric() %>%
    order()] %>% unique()
  dt[, n_ident := factor(n_ident, levels = vec_factorLevels, ordered = T), ]
  dt_sum <- dt[, .N, by = .(n_ident, group)]

  # ===============ggplot==================
  # colors
  if (is.null(vec_group_colors)) {
    n_group <- length(unique(dt$group))
    vec_group_colors <- f_color(n_group)
    names(vec_group_colors) <- unique(dt$group)
  }

  p <- ggplot(
    dt_sum,
    aes(x = n_ident, y = N, fill = factor(group))
  ) +
    geom_bar(
      position = "fill",
      stat = "identity",
      width = 0.6,
      show.legend = if (!is.null(fontsize_legendtext)) TRUE else FALSE
      # position=position_dodge()
    ) +
    scale_y_continuous(labels = scales::percent) +
    scale_fill_manual(values = vec_group_colors) +
    theme(
      axis.title.x = if (is.null(fontsize_axistitle_x)) element_blank() else element_text(size = fontsize_axistitle_x, vjust = 0),
      axis.text.x = if (is.null(fontsize_axistext_x)) element_blank() else element_text(angle = 90, size = fontsize_axistext_x, vjust = 0.5),
      axis.title.y = if (is.null(fontsize_axistitle_y)) element_blank() else element_text(size = fontsize_axistitle_y),
      axis.text.y = if (is.null(fontsize_axistext_y)) element_blank() else element_text(size = fontsize_axistext_y),
      legend.title = if (is.null(fontsize_legendtext)) element_blank() else element_text(size = fontsize_legendtitle),
      legend.text = if (is.null(fontsize_legendtext)) element_blank() else element_text(size = fontsize_legendtext),
      legend.background = element_blank(),
      legend.box.background = element_blank(),
      plot.background = element_blank(),
      aspect.ratio = aspect.ratio
    ) +
    labs(x = var_ident, y = "proportion", fill = var_group)

  if (do_plot) print(p)
  if (!is.null(output.dirs)) {
    grDevices::pdf(file = paste0("./", output.dirs, "/scPagwas.", output.prefix, ".bar_positie_nagtive1.pdf"), height = height, width = width)
    print(p)
    grDevices::dev.off()
  }

}
