library(igvR)
igv <- igvR()
setBrowserWindowTitle(igv, "Paired-end demo")
setGenome(igv, "hg38")
tbl.bedpe <- data.frame(chrom1=c("2","2"),
                        start1=c(105780000, 105575000),
                        end1=c(105790000, 105600000),
                        chrom2=c("2","2"),
                        start2=c(105890000, 106075000),
                        end2=c(105900000, 106100000),
                        stringsAsFactors=FALSE)

  # construct a "region of interest" (roi) string from tbl.bedpe
  # this is where our two features are found.

shoulder <- 300000
roi <- sprintf("%s:%d-%d", tbl.bedpe$chrom1[1],
                           min(tbl.bedpe$start1) - shoulder,
                           max(tbl.bedpe$end2) + shoulder)

showGenomicRegion(igv, roi)
track <- BedpeInteractionsTrack("ENCFF110BUX", tbl.bedpe)
displayTrack(igv, track)

  # TADs can come in with single base anchors.  make that work

tbl.bedpe2 <- tbl.bedpe[, c("chrom1", "start1", "start1", "chrom2", "start2", "start2")]
colnames(tbl.bedpe2)[c(3,5)] <- c("end1", "end2")
track <- BedpeInteractionsTrack("single-base anchors", tbl.bedpe2)
displayTrack(igv, track)

