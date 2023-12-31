#' @import httr
#'
#----------------------------------------------------------------------------------------------------
# log <- function(...)if(verbose) print(noquote(sprintf(...)))
#----------------------------------------------------------------------------------------------------
#' @title url.exists
#'
#' @description a helper function for mostly internal use, tests for availability of a url,
#'              modeled after file.exists
#'
#' @rdname url.exists
#' @aliases url.exists
#'
#' @param url character the http address to test
#'
#' @return logical TRUE or FALSE
#'
#' @export
url.exists <- function(url)
{
   response <- tolower(httr::http_status(httr::HEAD(url))$category)
   return(tolower(response) == "success")

} # url.exists
#----------------------------------------------------------------------------------------------------
#' @title currently.supported.stock.genomes
#' @description a helper function for mostly internal use, obtains the genome codes (e.g. 'hg38')
#'       supported by igv.js
#'
#' @rdname currently.supported.stock.genomes
#' @aliases currently.supported.stock.genomes
#'
#' @param test logical
#' @return an list of short genome codes, e.g., "hg38", "dm6", "tair10"
#' @export
#'
currently.supported.stock.genomes <- function(test=FALSE)
{
    basic.offerings <-  c("hg38", "hg19", "mm10", "tair10", "rhos", "custom", "dm6", "sacCer3")
    if(test) return(basic.offerings)

    current.genomes.file <- "https://s3.amazonaws.com/igv.org.genomes/genomes.json"

    if(!url.exists(current.genomes.file))
        return(basic.offerings)

    current.genomes.raw <- readLines(current.genomes.file, warn=FALSE, skipNul=TRUE)
    tbl.genomes <- fromJSON(current.genomes.raw)
    tbl.genomes$id

} # currently.supported.stock.genomes
#----------------------------------------------------------------------------------------------------
#' @title parseAndValidateGenomeSpec
#' @description a helper function for internal use by the igvShiny constructor, but possible also
#' of use to those building an igvShiny app, to test their genome specification for validity
#'
#' @rdname  parseAndValidateGenomeSpec
#' @aliases parseAndValidateGenomeSpec
#'
#' @param genomeName character usually one short code of a supported ("stock") genome (e.g., "hg38") or for
#'        a user-supplied custom genome, the name you wish to use
#' @param initialLocus character default "all", otherwise "chrN:start-end" or a recognized gene symbol
#' @param stockGenome logical default TRUE
#' @param dataMode character either "stock", "localFile" or "http"
#' @param fasta character when supplying a custom (non-stock) genome, either a file path or a URL
#' @param fastaIndex character when supplying a custom (non-stock) genome, either a file path or a URL,
#'     essential for all but the very small custom genomes.
#' @param genomeAnnotation character when supplying a custom (non-stock) genome, a file path or URL pointing
#'    to a genome annotation file in a gff3 format
#'
#' @examples
#' genomeSpec <- parseAndValidateGenomeSpec("hg38", "APOE")  # the simplest case
#' base.url <- "https://gladki.pl/igvr/testFiles/sarsGenome"
#' fasta.file <- sprintf("%s/%s", base.url,"Sars_cov_2.ASM985889v3.dna.toplevel.fa")
#' fastaIndex.file <-  sprintf("%s/%s", base.url, "Sars_cov_2.ASM985889v3.dna.toplevel.fa.fai")
#' annotation.file <-  sprintf("%s/%s", base.url, "Sars_cov_2.ASM985889v3.101.gff3")
#' custom.genome.title <- "SARS-CoV-2"
#' genomeOptions <- parseAndValidateGenomeSpec(genomeName=custom.genome.title,
#'                                             initialLocus="all",
#'                                             stockGenome=FALSE,
#'                                             dataMode="http",
#'                                             fasta=fasta.file,
#'                                             fastaIndex=fastaIndex.file,
#'                                             genomeAnnotation=annotation.file)
#'
#' @seealso [currently.supported.stock.genomes()] for stock genomes we support.
#'
#' @return an options list directly usable by igvApp.js, and thus igv.js
#' @export
#'
parseAndValidateGenomeSpec <- function(genomeName, initialLocus="all",
                                       stockGenome=TRUE,
                                       dataMode=NA, fasta=NA, fastaIndex=NA, genomeAnnotation=NA)
{
    options <- list()
    options[["stockGenome"]] <- stockGenome
    options[["dataMode"]] <- dataMode
    options[["validated"]] <- FALSE

    #--------------------------------------------------
    # first: is this a stock genome?  if so, we need
    # only check if the genomeName is recognized
    #--------------------------------------------------

    if(stockGenome){
       supported.stock.genomes <- currently.supported.stock.genomes()
       if(!genomeName %in% supported.stock.genomes){
          s.1 <- sprintf("Your genome '%s' is not currently supported", genomeName)
          s.2 <- sprintf("Currently supported: %s", paste(supported.stock.genomes, collapse=","))
          msg <- sprintf("%s\n%s", s.1, s.2)
          stop(msg)
          }
       options[["genomeName"]] <- genomeName
       options[["initialLocus"]] <- initialLocus
       options[["fasta"]] <- NA
       options[["fastaIndex"]] <- NA
       options[["annotation"]] <- NA
       options[["validated"]] <- TRUE
       }# stockGenome requested

    if(!stockGenome){
       stopifnot(!is.na(dataMode))
       stopifnot(!is.na(fasta))
       stopifnot(!is.na(fastaIndex))
         # genomeAnnotation is optional

       recognized.modes <- c("localFiles", "http")  # "direct" for an in-memory R data structure, deferred
       if(!dataMode %in% recognized.modes){
          msg <- sprintf("dataMode '%s' should be one of %s", dataMode, paste(recognized.modes, collapse=","))
          stop(msg)
          }
       #---------------------------------------------------------------------
       # dataMode determines how to check for the existence of each resource
       #---------------------------------------------------------------------

       exists.function <- switch(dataMode,
                                 "localFiles" = file.exists,
                                 "http" = url.exists
                                 )
       stopifnot(exists.function(fasta))
       stopifnot(exists.function(fastaIndex))
       if(!is.na(genomeAnnotation))
          stopifnot(exists.function(genomeAnnotation))

       options[["genomeName"]]  <- genomeName
       options[["fasta"]] <- fasta
       options[["fastaIndex"]] <- fastaIndex
       options[["initialLocus"]] <- initialLocus
       options[["annotation"]] <- genomeAnnotation
       options[["validated"]] <- TRUE
       } # if !stockGenome

    return(options)

} # parseAndValidateGenomeSpec
#----------------------------------------------------------------------------------------------------
