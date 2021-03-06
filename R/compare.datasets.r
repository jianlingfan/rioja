compare.datasets <- function(y1, y2, n.cut=c(5, 10, 20, 50), max.cut=c(2, 5, 10, 20, 50)) {
   y1 <- as.matrix(y1)
   y2 <- as.matrix(y2)
   nms1 <- colnames(y1)
   nms2 <- colnames(y2)
   mt <- match(nms1, nms2)
   mt.na <- as.integer(na.omit(mt))
   if (length(mt.na)==0)
      stop("There are no taxa in common between y1 and y2, cannot continue")
   y1.summ <- sp.summ(y1)[, 1:3]
   colnames(y1.summ) <- c("N.occur", "N2", "Max")
   y2.summ <- sp.summ(y2, n.cut=n.cut)
   m <- matrix(0, nrow=ncol(y1), ncol=ncol(y2.summ))
   colnames(m) <- colnames(y2.summ)
   colnames(m)[1:3] <- c("N.2", "N2.2", "Max.2")
   m[!is.na(mt), ] <- as.matrix(y2.summ[mt.na, ])
   sp <- data.frame(y1.summ, m)
   y1.summ2 <- site.summ(y1, max.cut=max.cut)
   nn <- length(n.cut)
   nmx <- length(max.cut)
   m2 <- matrix(0, nrow=nrow(y1), ncol=nn*2+nmx*2)
   for (i in 1:nn) {
      m2[, i] <- apply(y1, 1, function(x, cut, mx) sum(x>0 & mx>cut), cut=n.cut[i], mx=m[, "N2.2"])   
      m2[, i+nn] <- apply(y1, 1, function(x, cut, mx) sum(x * (mx>cut)), cut=n.cut[i], mx=m[, "N2.2"]) 
      
   }
   for (i in 1:nmx) {
      m2[, i+(nn*2)] <- apply(y1, 1, function(x, cut, mx) sum(x>0 & mx>cut), cut=max.cut[i], mx=m[, "Max.2"])   
      m2[, i+(nn*2)+nmx] <- apply(y1, 1, function(x, cut, mx) sum(x * (mx>cut)), cut=max.cut[i], mx=m[, "Max.2"])   
   }
   colnames(m2) <- c(paste("N2.", sprintf("%03d", n.cut), sep=""), paste("Sum.N2.", sprintf("%03d", n.cut), sep=""), paste("M2.", sprintf("%03d", max.cut), sep=""), paste("Sum.M2.", sprintf("%03d", max.cut),  sep=""))
   sites <- data.frame(y1.summ2, m2)
   result <- list(vars=sp, obs=sites)
   class(result) <- c("compare.datasets", "list")
   invisible(result)
}

