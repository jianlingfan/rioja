\name{read.Tilia}
\alias{read.Tilia}

\title{Read data in Tilia format}
\description{
Reads data in Tilia format used by the Tilia program for plotting stratigraphic diagrams.
}
\usage{
read.Tilia(fName)
}

\arguments{
  \item{fName}{ filename to read. }
}

\details{
 \code{read.Tila} reads data in the Tilia format. Tilia is a program written by Eric Grimm to plot stratigraphic diagrams and is popular with palynologists. Note that any spaces or other illegal characters in the species codes will be converted to decimal places on import.
}
\value{
Returns a list with three names elements:
\item{data}{ data frame with species as columns and sites as rows.  Column and row names are taken from the Tilia file. }
\item{vars}{ names and types of each variable in the dataset. }
\item{levels}{ names depths, and optionally ages of each level in the core. }
}

\note{
The code uses a C and C++. In particular, it uses a non-standard structure alignment for reading the Tilia headers. It works on Windows but has not been test on other platforms.  Please let me know of any problems.
}

\author{ 
Steve Juggins
}

\seealso{ 
\code{\link[rioja]{read.CEP}}.
}

\examples{
\dontrun{
pth <- system.file("example.datasets/WOLSFELD.TIL", package="rioja")
WOLS <- read.Tilia(pth)
sel <- WOLS$vars$Sums == "A" | WOLS$vars$Sums == "B"
spec <- WOLS$data[, sel]
totals <- apply(spec, 1, sum)
spec.pc <- spec / totals * 100
mx <- apply(spec.pc, 2, max)
spec.sub <- spec.pc[, mx > 5]
age <- WOLS$levels$Chron2
strat.plot(spec.sub, scale.percent=TRUE, yvar=age, y.rev=TRUE,
      wa.order="bottomleft")
}
}
\keyword{ IO }
\keyword{ file }