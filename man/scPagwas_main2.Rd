% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/scPagwas_main2.R
\name{scPagwas_main2}
\alias{scPagwas_main2}
\title{Main wrapper functions for scPagwas in version 2.0}
\usage{
scPagwas_main2(
  Pagwas = NULL,
  gwas_data = NULL,
  output.prefix = "Test",
  output.dirs = "scPagwastest_output",
  block_annotation = block_annotation,
  Single_data = NULL,
  assay = "RNA",
  Pathway_list = Genes_by_pathway_kegg,
  chrom_ld = chrom_ld,
  run_split = FALSE,
  n.cores = 1,
  marg = 10000,
  maf_filter = 0.01,
  min_clustercells = 10,
  min.pathway.size = 5,
  max.pathway.size = 300,
  iters_celltype = 200,
  iters_singlecell = 100,
  n_topgenes = 1000,
  singlecell = TRUE,
  celltype = TRUE,
  seurat_return = TRUE,
  remove_outlier = TRUE
)
}
\arguments{
\item{Pagwas}{= NULL: This parameter is typically not required and does not need any input data. When seurat_return = FALSE, all intermediate data is stored in the "Pagwas" list and returned as the result. This result can be inherited and used as input for subsequent calculations. In certain scenarios, such as when performing two computations with the same single-cell data input but different GWAS data inputs, the result list obtained from the first computation can be used as the "Pagwas" parameter input for the second computation. This allows skipping the single-cell calculations, significantly expediting the process. However, when seurat_return = TRUE, the returned result cannot be manipulated in this manner, as it is the final Seurat result with many intermediate data removed.}

\item{gwas_data}{(data.frame)GWAS summary data; It must have some
colmuns such as:
chrom|    pos    |   rsid    |   se  |  beta |  maf
6 | 119968580 | rs1159767 | 0.032 | 0.019 |0.5275
10 | 130566523 |  rs559109 | 0.033 | 0.045 |0.4047
5 | 133328825 | rs6893145 | 0.048 | 0.144 |0.1222
7 | 146652932 | rs13228798| 0.035 | 0.003 | 0.3211}

\item{output.prefix}{= "Test": This parameter sets the prefix for the output result files.}

\item{output.dirs}{= "scPagwastest_output": This parameter specifies the directory for the output result files.}

\item{block_annotation}{(data.frame) Start and end points for block
traits, usually genes.}

\item{Single_data}{(character or seurat)Input the Single data in seurat
format, or the seurat data address for rds format.Idents should be the celltypes annotation.}

\item{assay}{(character)assay data of your single cell data to use,
default is "RNA"}

\item{Pathway_list}{(list,character) pathway gene sets list}

\item{chrom_ld}{(list,numeric)LD data for 22 chromosome.}

\item{run_split}{(logical) Whether the input single cell data is a split sub-data, if TRUE,
one result(gPas score) is return, if FALSE, the whole function is running. default is FALSE.}

\item{n.cores}{cores for regression}

\item{marg}{(integr) the distance to TSS site,default is 10000, then
gene-TSS-window size is 20000.}

\item{maf_filter}{(numeric)Filter the maf, default is 0.01}

\item{min_clustercells}{(integr)Only use is when FilterSingleCell is
TRUE.Threshold for total cells fo each cluster.default is 10}

\item{min.pathway.size}{(integr)Threshold for min pathway gene size.
default is 5}

\item{max.pathway.size}{(integr)Threshold for max pathway gene size.
default is 300}

\item{iters_celltype}{(integr)number of bootstrap iterations for celltype}

\item{iters_singlecell}{(integr)number of bootstrap iterations for singlecell；
The parameter "iters_singlecell" is used to calculate the significance p-value for individual cells. However, we have observed that this step requires a significant amount of computational memory. Therefore, we do not recommend selecting a large value for this parameter initially.If you do not want to waste time calculating the p-value, you can choose to set it as 0.}

\item{n_topgenes}{(integr)Number of top associated gene selected to
calculate the scPagwas score;}

\item{singlecell}{(logical)Whether to produce the singlecell result;}

\item{celltype}{(logical)Whether to produce the celltypes result;}

\item{seurat_return}{(logical) Whether return the seurat format result,
if not,will return a list result;}

\item{remove_outlier}{(logical)Whether to remove the outlier for
scPagwas score.}
}
\value{
Returns a seurat data with entries(seurat_return=T):
\describe{
\item{assay:}{
{scPagwasPaPca:}{An assay for S4 type of data; the svd result
for pathways in each cells;}
{scPagwasPaHeritability:}{An assay for S4 type of data; the
gPas matrix for pathways in each cells;}}
\item{meta.data}{
{scPagwas.TRS.Score1:}{ the column for "meta.data";Enrichment socre
for inheritance associated top genes.}
{scPagwas.gPAS.score:}{ the column for "meta.data";Inheritance
regression effects for each cells}
{Random_Correct_BG_p}{: CellpValue for each cells;}
{Random_Correct_BG_adjp}{: fdr for each cells, adjust p value.}
{Random_Correct_BG_z}{: z score for eahc cells.}
\item{misc: element in result,\code{Pagwas@misc }}{
{Pathway_list:}{a list for pathway gene list intersecting with single
cell data}
{pca_cell_df:}{ a data frame for pathway pca result for each celltype.}
{lm_results:}{ the regression result for each cell.}
{PCC:}{
heritability correlation value for each gene;In the previous version, we referred to it as Pearson correlation coefficients.}
{bootstrap_results:}{The bootstrap data frame results for celltypes
including bootstrap pvalue and confidence interval.}
}

}
Returns files:

\describe{
{scPagwas.run.log:}{ the running log file for scPagwas}
{\emph{_parameters.txt:}{parameters log file for scPagwas}
{}_singlecell_scPagwas_score.Result.csv:}{ The final result for
lm and top gene score}
{\emph{_celltypes_bootstrap_results.csv:}{The bootstrap data frame
results for celltypes including bootstrap pvalue and confidence
interval}
{}_gene_PCC.csv:}{ heritability correlation
value("cor" for pearson) for each gene;}
}

Returns a list class with entries(seurat_return=F):
\describe{
{scPagwasPaPca:}{Assays for S4 type of data; the svd result for
pathways in each cells;}
{scPagwas.topgenes.Score1:}{ the column for "meta.data";
Enrichment socre for inheritance associated top genes.}
{sclm_score:}{ the column for "meta.data";Inheritance regression
effects for each cells}
{Pathway_list:}{ The number of Lanczos iterations carried out}
{pca_cell_df:}{ The total number of matrix vector products carried out}
{sclm_results:}{ The total number of matrix vector products carried out}
{PCC:}{ The total number of
matrix vector products carried out;In the previous version, we referred to it as Pearson correlation coefficients}
{Pathway_ctlm_results:}{ The total number of matrix vector products
carried out}
{lm_results:}{ The total number of matrix vector products carried out}
{Pathway_ct_results:}{ The total number of matrix vector products
carried out}
}
}
\description{
Main Pagwas wrapper functions in version 2.0.
}
\details{
The entry point for Pagwas analysis. Including the data input...
Including the data input functions and the main progress functions;
It can also output the
running log and parameter log for scPagwas, and construct the folder
for output.
}
\author{
Chunyu Deng
}
\keyword{2.0.}
\keyword{functions}
\keyword{in}
\keyword{of}
\keyword{scPagwas}
\keyword{scPagwas_main2,}
\keyword{version}
\keyword{wrapper}
