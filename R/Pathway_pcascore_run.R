
#' Pathway_pcascore_run
#' @description The function can calculate the pathway pcascore for
#' celltypes and single cells.
#' @param Pagwas Pagwas format
#' @param Pathway_list Pathawy gene list(gene symbol),list name is
#' pathway name.
#' @param min.pathway.size Threshold for min pathway gene size.
#' @param max.pathway.size Threshold for max pathway gene size.
#'
#' @return pca score for pathway in single data and celltypes
#' @export
#'
#' @examples
#' library(scPagwas)
#' Pagwas <- list()
#' # Start to read the single cell data
#' Single_data <- readRDS(system.file("extdata", "scRNAexample.rds",
#'   package = "scPagwas"
#' ))
#' Pagwas <- Single_data_input(
#'   Pagwas = Pagwas,
#'   assay = "RNA",
#'   Single_data = Single_data,
#'   Pathway_list = Genes_by_pathway_kegg
#' )
#' Single_data <- Single_data[, colnames(Pagwas$data_mat)]
#' # Run pathway pca score!
#' Pagwas <- Pathway_pcascore_run(
#'   Pagwas = Pagwas,
#'   Pathway_list = Genes_by_pathway_kegg
#' )
#' @author Chunyu Deng
#' @aliases Pathway_pcascore_run
#' @keywords Pathway_pcascore_run, calculate the svd matrix for singlecell
#' data.

Pathway_pcascore_run <- function(Pagwas = NULL,
                                 Pathway_list = NULL,
                                 min.pathway.size = 10,
                                 max.pathway.size = 1000) {
  if (is.null(Pathway_list)) {
    stop("not loaded Pathway_list data")
  }

  if (!("list" %in% class(Pathway_list))) {
    stop("not loaded the list format of Pathway_list data")
  }

  # filter the pathway length
  Pa.len <- unlist(lapply(Pathway_list, function(Pa) length(Pa)))

  Pathway_list <- Pathway_list[names(Pathway_list)[Pa.len >= min.pathway.size &
    Pa.len <= max.pathway.size]]

  # Valid the total genes of pathway.
  pa_gene <- unique(unlist(Pathway_list))
  if (length(intersect(rownames(Pagwas$data_mat), pa_gene)) < length(pa_gene) * 0.1) {
    stop("There are less 10% intersect genes between Single_data and
         Pathway_list, please check the gene names")
  }

  # filter the scarce pathway
  pana <- names(Pathway_list)[which(
    unlist(lapply(
      Pathway_list,
      function(Pa) {
        length(intersect(
          Pa,
          Pagwas$VariableFeatures
        ))
      }
    )) > 2
  )]
  Pathway_list <- Pathway_list[pana]
  # keep the raw pathway
  Pagwas$rawPathway_list <- Pathway_list

  # filter the gene for no expression in single cells in pathway
  celltypes <- as.vector(unique(Pagwas$Celltype_anno$annotation))

  pana_list <- lapply(celltypes, function(celltype) {
    scCounts <- Pagwas$data_mat[
      ,
      Pagwas$Celltype_anno$cellnames[
        Pagwas$Celltype_anno$annotation == celltype
      ]
    ]
  if (!inherits(scCounts, "matrix")) {
    scCounts <- as_matrix(scCounts)
  }

    scCounts <- scCounts[rowSums(scCounts) != 0, ]
    proper.gene.names <- rownames(scCounts)
    pana <- names(Pathway_list)[which(
      unlist(lapply(
        Pathway_list,
        function(Pa) {
          length(intersect(
            Pa, proper.gene.names
          ))
        }
      )) > 2
    )]
    return(pana)
  })

  Pagwas$Pathway_list <- Pathway_list[Reduce(intersect, pana_list)]
  Pagwas$rawPathway_list <- Pathway_list[Reduce(intersect, pana_list)]
  rm(pana_list)
  rm(Pathway_list)

  message("* Start to get Pathway SVD socre!")
  pb <- txtProgressBar(style = 3)
  scPCAscore_list <- lapply(celltypes, function(celltype) {
    scCounts <- Pagwas$data_mat[
      ,
      Pagwas$Celltype_anno$cellnames[
        Pagwas$Celltype_anno$annotation == celltype
      ]
    ]
  if (!inherits(scCounts, "matrix")) {
    scCounts <- as_matrix(scCounts)
  }
    scPCAscore <- PathwayPCAtest(
      Pathway_list = Pagwas$Pathway_list,
      scCounts = scCounts
    )
    setTxtProgressBar(pb, which(celltypes == celltype) / length(celltypes))
    print(celltype)
    return(scPCAscore)
  })
  close(pb)
  #remove pathway
  pa_remove<-unique(unlist(lapply(
    seq_len(length(scPCAscore_list)), function(i) {
      scPCAscore_list[[i]][[3]]
    })))

  ## merge all PCAscore list
  pca_df <- lapply(seq_len(length(scPCAscore_list)), function(i) {
    df <- scPCAscore_list[[i]][[1]]
    if(length(pa_remove)!=0){
      df<-df[df$name != pa_remove,]
    }
    df$celltype <- rep(celltypes[i], nrow(df))
    return(df)
  })
  pca_df <- Reduce(function(dtf1, dtf2) rbind(dtf1, dtf2), pca_df)
  pca_scoremat <- reshape2::dcast(
    pca_df[, c("name", "celltype", "score")], name ~ celltype
  )
  rm(pca_df)

  rownames(pca_scoremat) <- pca_scoremat$name

  if (dim(pca_scoremat)[2] == 2) {
    pca_cell_df <- data.matrix(pca_scoremat[, -1])
  } else {
    pca_cell_df <- pca_scoremat[, -1]
  }
  rownames(pca_cell_df) <- pca_scoremat$name

  colnames(pca_cell_df) <- colnames(pca_scoremat)[-1]

  rm(pca_scoremat)

  index <- !is.na(pca_cell_df[1, ])

  if (sum(index) < ncol(pca_cell_df)) {
    message(colnames(pca_cell_df)[!index], " have no information, delete!")
    pca_cell_df <- pca_cell_df[, index]
  }

  pca_scCell_mat <- bigreadr::cbind_df(lapply(seq_len(length(scPCAscore_list)), function(i) {
    df<-scPCAscore_list[[i]][[2]]
    pa<-setdiff(rownames(df),pa_remove)
    df<-df[pa,]
    return(df)
  }))
  rm(scPCAscore_list)
  colnames(pca_scCell_mat) <- colnames(Pagwas$data_mat)

  options(bigmemory.allow.dimnames = TRUE)
  Pagwas$pca_scCell_mat <- data.matrix(pca_scCell_mat)

  colnames(Pagwas$merge_scexpr) <- colnames(pca_cell_df)

  Pagwas$VariableFeatures <- intersect(
    rownames(Pagwas$data_mat),
    Pagwas$VariableFeatures
  )

  Pagwas$pca_cell_df <- pca_cell_df
  if(length(pa_remove)!=0){
  Pagwas$Pathway_list <- Pagwas$Pathway_list[rownames(pca_scCell_mat)]
  Pagwas$rawPathway_list <- Pagwas$rawPathway_list[rownames(pca_scCell_mat)]
  }
  return(Pagwas)
}


#' PathwayPCAtest
#' @description Calculate pca score
#' @param Pathway_list Pathawy gene list(gene symbol),list name is pathway name.
#' @param scCounts single cell Counts pathway
#'
#' @return list of pca score
#'
#' library(scPagwas)
#' Pathway_list<-
PathwayPCAtest <- function(Pathway_list,
                           scCounts) {
  if (any(duplicated(rownames(scCounts)))) {
    stop("Duplicate gene names are not allowed - please reduce")
  }
  if (any(duplicated(colnames(scCounts)))) {
    stop("Duplicate cell names are not allowed - please reduce")
  }
  if (any(is.na(rownames(scCounts)))) {
    stop("NA gene names are not allowed - please fix")
  }
  if (any(is.na(colnames(scCounts)))) {
    stop("NA cell names are not allowed - please fix")
  }


  ## filter pathway
  nPcs <- 1
  scCounts <- t(scCounts)

  cm <- Matrix::colMeans(scCounts)
  proper.gene.names <- colnames(scCounts)

  ###### calculate the pca for each pathway terms.
  papca <- lapply(Pathway_list, function(Pa_id) {
    #print(id)
    #Pa_id<-Pathway_list[[id]]
    lab <- proper.gene.names %in% intersect(proper.gene.names, Pa_id)
    mat <- scCounts[, lab]
    result <- tryCatch(
      {
    pcs <- irlba::irlba(mat,
      nv = nPcs, nu = 0, center = cm[lab]
    )
    pcs$d <- pcs$d / sqrt(nrow(mat))
    pcs$rotation <- pcs$v
    pcs$v <- NULL


    pcs$scores <- Matrix::crossprod(
      pcs$rotation,
      t(mat)
    ) - as.numeric((cm[lab] %*% pcs$rotation))

    cs <- unlist(lapply(
      seq_len(nrow(pcs$scores)),
      function(i) {
        sign(stats::cor(
          pcs$scores[i, ],
          colMeans(t(mat) * abs(pcs$rotation[, i]))
        ))
      }
    ))

    pcs$scores <- pcs$scores * cs
    pcs$rotation <- pcs$rotation * cs
    rownames(pcs$rotation) <- colnames(mat)

    return(list(xp = pcs))
      },
    error = function(e) {
      return(NULL)
    }
    )
  })

  pa_remove<-names(papca)[sapply(papca,is.null)]
  papca<-papca[!sapply(papca,is.null)]

  vdf <- data.frame(do.call(rbind, lapply(seq_along(papca), function(i) {
    result <- tryCatch(
      {
        vars <- as.numeric((papca[[i]]$xp$d))
        cbind(
          i = i, var = vars, n = papca[[i]]$n,
          npc = seq(seq_len(ncol(papca[[i]]$xp$rotation)))
        )
      },
      error = function(e) {
        return(NULL)
      }
    )
  })))

  vscore <- data.frame(do.call(rbind, lapply(seq_along(papca), function(i) {
    papca[[i]]$xp$scores
  })))

  n.cells <- nrow(scCounts)

  vdf$exp <- RMTstat::qWishartMax(0.5, n.cells, vdf$n,
    var = 1, lower.tail = FALSE
  )
  vdf$var <- (vdf$var) / (vdf$exp)
  df <- data.frame(
    name = names(papca)[vdf$i],
    score = vdf$var,
    stringsAsFactors = FALSE
  )

  rownames(vscore) <- names(papca)[vdf$i]
  colnames(vscore) <- rownames(scCounts)

  return(list(df, vscore,pa_remove))
}
