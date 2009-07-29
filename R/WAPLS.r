WAPLS <- function(y, x, npls=5, iswapls=TRUE, standx=FALSE, lean=FALSE, check.data=TRUE, ...)
{
  y <- as.matrix(y)
  if (!is.null(dim(x)))
     x <- x[, 1]
  if (check.data) {
    if (any(apply(y, 1, sum) < 1.0E-8))
       stop(paste("Species data have zero abundaces for the following rows:", paste(which(apply(y, 1, sum) < 1.0E-8), collapse=",")))
    if (any(apply(y, 2, sum) < 1.0E-8))
       stop(paste("Species data have zero abundaces for the following columns:", paste(which(apply(y, 2, sum) < 1.0E-8), collapse=",")))
  }
  model <- WAPLS.fit(y,x,npls, iswapls, standx, lean)
  xHat <- predict.internal.WAPLS(model, y, lean)
  call.fit <- as.call(list(quote(WAPLS.fit), y=quote(y), x=quote(x), npls=npls, iswapls=iswapls, standx=standx, lean=lean))
  call.print <- match.call()
	result <- c(model, list(npls=npls, fitted.values=xHat, call.fit=call.fit, call.print=call.print, x=x))
	if (!lean) 
	   result$y <- y
  class(result) <- c("WAPLS")
  result$cv.summary <- list(cv.method="none")
	result
}

WAPLS.fit <- function(y, x, npls=5, iswapls=TRUE, standx=FALSE, lean=FALSE)
{
  y <- as.matrix(y)
  x <- as.numeric(x)
  result <- .Call("WAPLS_fit", y, x, as.integer(npls), as.integer(iswapls), as.integer(standx), as.integer(lean), PACKAGE="rioja")
  beta <- matrix(result$Beta, nrow=ncol(y))
  if (!lean) {
    rownames(beta) <- colnames(y)
    colnames(beta) <- paste("Comp", formatC(1:ncol(beta), width=2, flag="0"), sep="")
    if (ncol(beta) != npls)
       warning(paste("Only", ncol(beta), "components could be extracted"))
  }
  ret <- list(coefficients=beta, meanY=result$meanY, iswapls=iswapls)
  if (!lean) {
    T <- matrix(result$T, nrow=nrow(y))
    P <- matrix(result$P, nrow=ncol(y))
    rownames(T) <- rownames(y)
    rownames(P) <- colnames(y)
    colnames(T) <- paste("Comp", formatC(1:ncol(T), width=2, flag="0"), sep="")
    colnames(P) <- paste("Comp", formatC(1:ncol(P), width=2, flag="0"), sep="")
    ret$T <- T
    ret$P <- P
  }
  if (!iswapls)
    ret <- c(ret, list(standx=standx, meanT=result$sdX, sdx=result$sdX))
	ret
}

predict.internal.WAPLS <- function(object, y, lean=FALSE, ...)
{
  if (!lean) {
    if (nrow(object$coefficients) != ncol(y))
       stop("Number of taxa does not match that in model")
    if (any(colnames(y) != rownames(object$coefficients)))
       stop("Taxon names do not match those in model")
  }
  y <- as.matrix(y)
  xHat <- .Call("WAPLS_predict", y, object$coefficients, object$meanY, object$iswapls, object$standx, object$sdx, object$meanT, PACKAGE="rioja")
  xHat <- matrix(xHat, nrow=nrow(y))
  if (!lean) {
    rownames(xHat) <- rownames(y)
    colnames(xHat) <- paste("Comp", formatC(1:ncol(xHat), width=2, flag="0"), sep="")
  }
	xHat
}

predict.WAPLS <- function(object, newdata=NULL, sse=FALSE, nboot=100, match.data=TRUE, verbose=TRUE, ...) {
  .predict(object=object, newdata=newdata, sse=sse, nboot=nboot, match.data=match.data, verbose=verbose, ...)
}

crossval.WAPLS <- function(object, cv.method="loo", verbose=TRUE, ngroups=10, nboot=100, ...) {
  .crossval(object=object, cv.method=cv.method, verbose=verbose, ngroups=ngroups, nboot=nboot, ...)
}

performance.WAPLS <- function(object, ...) {
  .performance(object, ...)
}

print.WAPLS <- function(x, ...) 
{
  cat("\n")
  cat("Method : Weighted Averaging Partial Least Squares\n")
  cat("Call   : ")
  cat(paste(deparse(x$call.print), "\n\n"))
  cat(paste("No. samples  :", length(x$x), "\n"))
  cat(paste("No. species  :", nrow(x$coefficients), "\n"))
  .print.crossval(x)
  cat("\nPerformance:\n")
  .print.performance(x)
  cat("\n")
}

summary.WAPLS <- function(object, full=FALSE, ...) 
{
  print(object, ...)
  if (object$cv.summary$cv.method == "none")
    fitted <- as.data.frame(object$fitted.values)     
  else
    fitted <- as.data.frame(object$fitted.values, object$predicted)     
  cat("\nFitted values\n")
  if (full) {
     print(fitted)
     cat("\nSpecies coefficients\n")
     print(data.frame(object$coefficients))
  } else {
     print(dot(fitted))
     cat("\nSpecies coefficients\n")
     print(dot(data.frame(object$coefficients)))
  }
}

screeplot.WAPLS <- function(x, rand.test=TRUE, ...) {
  if (x$cv.summary$cv.method=="none")
     stop("WAPLS model does not have cross validation estimates")
  summ <- performance(x)
  yR <- range(summ$object[, "RMSE"], summ$crossval[, "RMSE"])
  oldmar <- par("mar")
  if (rand.test) {
    mm <- oldmar
    mm[4] <- mm[4] * 2
    par(mar=mm)
  }
  plot(1:x$npls, summ$object[, "RMSE"], type="b", ylim=yR, col="black", xlab="Number of components", ylab="RMSE", las=1)
  lines(1:x$npls, summ$crossval[, "RMSE"], type="b", col="red")
  axis(2)
  axis(1, at=1:length(x$npls), labels=1:length(x$npls))
  box()
  args <- names(as.list(match.call()))
  if ("main" %in% args) 
     title(...)
  else 
     title(main=substitute(x))
  if (rand.test) {
    res <- rand.t.test(x, ...)
    rY <- range(pretty(res[-1, "delta.RMSE"]), na.rm=TRUE)
    us <- par("usr")
    us[3] <- rY[1]
    us[4] <- rY[2]
    par(usr=us)
    axis(4, las=1)
    lines(1:x$npls, res[, "delta.RMSE"], type="b", col="blue")
    mtext("% change in RMSE", 4, line=2)
    text(1:x$npls, res[, "delta.RMSE"], as.character(round(res[, "p"], 3)), pos=2, xpd=NA, cex=0.8, col="blue") 
    legend("bottomleft", c("model RMSE", "x-val RMSE", "% change RMSE"), lty=1, col=c("black", "red", "blue"))
    par(mar=oldmar)
    invisible(res)
  }
  else  
     legend("topright", c("model", "x-val"), lty=1, col=c("black", "red"))
}

plot.WAPLS <- function(x, resid=FALSE, xval=FALSE, npls=1, xlab="", ylab="", ylim=NULL, xlim=NULL, add.ref=TRUE, add.smooth=FALSE, ...) {
  if (xval & x$cv.summary$cv.method=="none")
     stop("WAPLS model does not have cross validation estimates")
  xx <- x$x
  if (resid) {
     if (xval) {
       yy <- x$predicted[, npls] - x$x
     } else {
       yy <- residuals(x)[, npls]
     }
  } else {
     if (xval) {
        yy <- x$predicted[, npls]
      }  else {
       yy <- x$fitted.values[, npls]
      }
  }
  if (missing(ylim)) {
     if (resid) {
       ylim <- range(yy)
     } else {
       ylim <- range(yy, x$x)
     }
  }
  if (missing(xlim))
     xlim <- range(xx, x$x)
  plot(xx, yy, ylim=ylim, xlim=xlim, xlab=xlab, ylab=ylab, las=1)
  if (add.ref) {
     if (resid)
       abline(h=0, col="grey")
     else
       abline(0,1, col="grey")
  }
  if (add.smooth) {
     lines(lowess(xx, yy))
  }
}

fitted.WAPLS <- function(object, ...) {
  object$fitted.values
}

residuals.WAPLS <- function(object, ...) {
  object$x - object$fitted.values
}

coef.WAPLS <- function(object, ...) {
  object$coefficients
}

rand.t.test.WAPLS <- function(object, n.perm=999, ...) 
{ 
  if (object$cv.summary$cv.method=="none")
     stop("Can only perform a randomisation t-test on a cross-validated model.")
  p <- performance(object)
  if (object$npls < 2)
     stop("Only one component - nothing to test.")
  npls <- nrow(p$crossval)
  delta <- diff(p$crossval[, 1]) / p$crossval[1:(npls-1)] * 100
  e <- object$residuals.cv
  t.res <- vector("numeric",npls)
  t.res[] <- NA
  for (i in 2:npls) {
    d <- e[, i-1]^2 - e[, i]^2
    t.obs <- mean(d, na.rm=TRUE)
    t.sum <- 0
    for (j in 1:n.perm) {
      rnd <- sample(c(TRUE, FALSE), 100, replace=TRUE)
      d2 <- ifelse(rnd, abs(d), -abs(d))
      t <- mean(d2, na.rm=TRUE)
      if (t >= t.obs)
         t.sum <- t.sum + 1
    }
    t.res[i] <- t.sum / (n.perm+1)
  }
  result <- cbind(p$crossval, delta.RMSE=c(NA, delta), p=t.res)
  result
}
