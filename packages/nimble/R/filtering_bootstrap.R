##  Contains code to run bootstrap particle filters.
##  We have a build function (buildBootstrapFilter),
##  and step function.


bootStepVirtual <- nimbleFunctionVirtual(
  run = function(m = integer(), threshNum=double(), prevSamp = logical()) 
    returnType(double(1))
)


# Bootstrap filter as specified in Doucet & Johnasen '08,
# uses weights from previous time point to calculate likelihood estimate.

bootFStep <- nimbleFunction(
  contains = bootStepVirtual,
  setup = function(model, mvEWSamples, mvWSamples, nodes, iNode, names, saveAll, smoothing, silent = FALSE) {
    notFirst <- iNode != 1
    prevNode <- nodes[if(notFirst) iNode-1 else iNode]
    thisNode <- nodes[iNode]
    prevDeterm <- model$getDependencies(prevNode, determOnly = TRUE)
    thisDeterm <- model$getDependencies(thisNode, determOnly = TRUE)
    thisData   <- model$getDependencies(thisNode, dataOnly = TRUE)
    t <- iNode  # current time point
    # Get names of xs node for current and previous time point (used in copy)
    if(saveAll == 1){
      allPrevNodes <- model$expandNodeNames(nodes[1:(iNode-1)])
      prevXName <- prevNode    
      thisXName <- thisNode
      currInd <- t
      prevInd <- t-1
      if(smoothing == T){
        currInd <- 1
        prevInd <- 1
      }
    }
    else{
      allPrevNodes <- names
      prevXName <- names    
      thisXName <- names
      currInd <- 1
      prevInd <- 1 
    }
    isLast <- (iNode == length(nodes))
  },
  run = function(m = integer(), threshNum = double(), prevSamp = logical()) {
    returnType(double(1))
    ##declare(wts, double(1, m))
    wts <- numeric(m, init=FALSE)
    ids <- integer(m, 0)
    ##declare(llEst, double(1,m))
    llEst <- numeric(m, init=FALSE)
    ##declare(out, double(1,2))
    out <- numeric(2, init=FALSE)
    
    for(i in 1:m) {
      if(notFirst) {  
        if(smoothing == 1){
          copy(mvEWSamples, mvWSamples, nodes = allPrevNodes, nodesTo = allPrevNodes, row = i, rowTo=i)
        }
        copy(mvEWSamples, model, nodes = prevXName, nodesTo = prevNode, row = i)
        calculate(model, prevDeterm) 
      }
      simulate(model, thisNode)
      copy(model, mvWSamples, nodes = thisNode, nodesTo = thisXName, row = i)
      calculate(model, thisDeterm)
      wts[i]  <- calculate(model, thisData)
      if(is.nan(wts[i])){
        out[1] <- -Inf
        out[2] <- 0
        return(out)
      }
      if(prevSamp == 0){
        llEst[i] <- wts[i] + mvWSamples['wts',i][prevInd]
      }
      else{
          llEst[i] <- wts[i] - log(m)
      }
    }
    
    stepllEst <- log(sum(exp(llEst)))
    if(is.nan(stepllEst)){
      out[1] <- -Inf
      out[2] <- 0
      return(out)
    }
    if(stepllEst == Inf | stepllEst == -Inf){
      out[1] <- -Inf
      out[2] <- 0
      return(out)
    }
    
    out[1] <- stepllEst
    
    # Normalize weights and calculate effective sample size 
    wts <- exp(wts)/sum(exp(wts))
    ess <- 1/sum(wts^2) 
    
    # Determine whether to resample by weights or not
    if(ess < threshNum){
      rankSample(wts, m, ids, silent)
      # out[2] is an indicator of whether resampling takes place
      # affects how ll estimate is calculated at next time point.
      out[2] <- 1
      for(i in 1:m){
        copy(mvWSamples, mvEWSamples, nodes = thisXName, nodesTo = thisXName, row = ids[i], rowTo = i)
        if(smoothing == 1){
          copy(mvWSamples, mvEWSamples, nodes = allPrevNodes, nodesTo = allPrevNodes, row = ids[i], rowTo=i)
        }
        mvWSamples['wts',i][currInd] <<- log(wts[i])
      }
    }
    else{
      out[2] <- 0
      for(i in 1:m){
        copy(mvWSamples, mvEWSamples, nodes = thisXName, nodesTo = thisXName, row = i, rowTo = i)
        if(smoothing == 1){
          copy(mvWSamples, mvEWSamples, nodes = allPrevNodes, nodesTo = allPrevNodes, row = i, rowTo=i)
        }
        mvWSamples['wts',i][currInd] <<- log(wts[i])
      }
    }
    return(out)
  }, where = getLoadingNamespace()
)

#' Create a bootstrap particle filter algorithm to estimate log-likelihood.
#'
#'@description Create a bootstrap particle filter algorithm for a given NIMBLE state space model.  
#'
#' @param model A nimble model object, typically representing a state 
#'  space model or a hidden Markov model
#' @param nodes A character vector specifying the latent model nodes 
#'  over which the particle filter will stochastically integrate over to
#'  estimate the log-likelihood function
#' @param control  A list specifying different control options for the particle filter.  Options are described in the details section below.
#' @author Daniel Turek and Nicholas Michaud
#' @details 
#' 
#' Each of the \code{control()} list options are described in detail here:
#' \describe{
#'  \item{thresh}{ A number between 0 and 1 specifying when to resample: the resampling step will occur when the
#'   effective sample size is less than \code{thresh} times the number of particles.  Defaults to 0.8.}
#'  \item{saveAll}{Indicates whether to save state samples for all time points (TRUE), or only for the most recent time point (FALSE)}
#'  \item{smoothing}{Decides whether to save smoothed estimates of latent states, i.e., samples from f(x[1:t]|y[1:t]) if \code{smoothing = TRUE}, or instead to save filtered samples from f(x[t]|y[1:t]) if \code{smoothing = FALSE}.  \code{smoothing = TRUE} only works if \code{saveAll = TRUE}.}
#'  \item{timeIndex}{An integer used to manually specify which dimension of the latent state variable indexes time.  
#'  Only needs to be set if the number of time points is less than or equal to the size of the latent state at each time point.}
#' }
#' 
#'  The bootstrap filter starts by generating a sample of estimates from the 
#'  prior distribution of the latent states of a state space model.  At each time point, these particles are propagated forward 
#'  by the model's transition equation.  Each particle is then given a weight 
#'  proportional to the value of the observation equation given that particle. 
#'  The weights are used to draw an equally-weighted sample of the particles at this time point.
#'  The algorithm then proceeds
#'  to the next time point.  Neither the transition nor the observation equations are required to 
#'  be normal for the bootstrap filter to work.   
#'  
#'  The resulting specialized particle filter algorthm will accept a
#'  single integer argument (\code{m}, default 10,000), which specifies the number
#'  of random \'particles\' to use for estimating the log-likelihood.  The algorithm 
#'  returns the estimated log-likelihood value, and saves
#'  unequally weighted samples from the posterior distribution of the latent
#'  states in the \code{mvWSamples} modelValues object, with corresponding logged weights in \code{mvWSamples['wts',]}.
#'  An equally weighted sample from the posterior can be found in the \code{mvEWsamp} \code{modelValues} object.
#'
#' @export
#' 
#' @family particle filtering methods
#' @references Gordon, N.J., D.J. Salmond, and A.F.M. Smith. (1993). Novel approach to nonlinear/non-Gaussian Bayesian state estimation. \emph{IEEE Proceedings F (Radar and Signal Processing)}. Vol. 140. No. 2. IET Digital Library, 1993.
#' @examples
#' \dontrun{
#' model <- nimbleModel(code = ...)
#' my_BootF <- buildBootstrapFilter(model, 'x[1:100]')
#' Cmodel <- compileNimble(model)
#' Cmy_BootF <- compileNimble(my_BootF, project = model)
#' logLike <- Cmy_BootF(m = 100000)
#' boot_X <- as.matrix(Cmy_BootF$mvEWSamples)
#' }
buildBootstrapFilter <- nimbleFunction(
  setup = function(model, nodes, control = list()) {
    
    #control list extraction
    thresh <- control[['thresh']]
    saveAll <- control[['saveAll']]
    smoothing <- control[['smoothing']]
    silent <- control[['silent']]
    timeIndex <- control[['timeIndex']]
    if(is.null(thresh)) thresh <- .8
    if(is.null(silent)) silent <- TRUE
    if(is.null(saveAll)) saveAll <- FALSE
    if(is.null(smoothing)) smoothing <- FALSE
    
    #latent state info
    varName <- sapply(nodes, function(x){return(model$getVarNames(nodes = x))})
    if(length(unique(varName))>1){
      stop("all latent nodes must come from same variable")
    }
    varName <- varName[1]
    info <- model$getVarInfo(varName)
    latentDims <- info$nDim
    if(is.null(timeIndex)){
      timeIndex <- which.max(info$maxs)
      timeLength <- max(info$maxs)
      if(sum(info$maxs==timeLength)>1) # check if multiple dimensions share the max index size
        stop("unable to determine which dimension indexes time. 
             Specify manually using the 'timeIndex' control list argument")
    } else{
      timeLength <- info$maxs[timeIndex]
    }
    
    my_initializeModel <- initializeModel(model, silent = silent)
    
    nodes <- paste(info$varName,"[",rep(",", timeIndex-1), 1:timeLength,
                   rep(",", info$nDim - timeIndex),"]", sep="")
    dims <- lapply(nodes, function(n) nimDim(model[[n]]))
    if(length(unique(dims)) > 1) stop('sizes or dimensions of latent states varies')
    vars <- model$getVarNames(nodes =  nodes)  # need var names too
    
    if(0>thresh || 1<thresh || !is.numeric(thresh)) stop('thresh must be between 0 and 1')
    if(!saveAll & smoothing) stop("must have saveAll = TRUE for smoothing to work")
    # Create mv variables for x state and sampled x states.  If saveAll=TRUE, 
    # the sampled x states will be recorded at each time point.
    modelSymbolObjects <- model$getSymbolTable()$getSymbolObjects()[vars]
    if(saveAll){
      
      names <- sapply(modelSymbolObjects, function(x)return(x$name))
      type <- sapply(modelSymbolObjects, function(x)return(x$type))
      size <- lapply(modelSymbolObjects, function(x)return(x$size))
      
      mvEWSamples <- modelValues(modelValuesConf(vars = names,
                                              types = type,
                                              sizes = size))
      
      names <- c(names, "wts")
      type <- c(type, "double")
      size$wts <- length(dims)
      if(smoothing == TRUE)
        size$wts <- 1  ##  only need one weight per particle (at time T) if smoothing == TRUE
      mvWSamples  <- modelValues(modelValuesConf(vars = names,
                                              types = type,
                                              sizes = size))
      
    }
    else{
      names <- sapply(modelSymbolObjects, function(x)return(x$name))
      type <- sapply(modelSymbolObjects, function(x)return(x$type))
      size <- lapply(modelSymbolObjects, function(x)return(x$size))
      size[[1]] <- as.numeric(dims[[1]])
      
      mvEWSamples <- modelValues(modelValuesConf(vars = names,
                                              types = type,
                                              sizes = size))
      
      names <- c(names, "wts")
      type <- c(type, "double")
      size$wts <- 1
      mvWSamples  <- modelValues(modelValuesConf(vars = names,
                                              types = type,
                                              sizes = size))
      names <- names[1]
    }
    
    bootStepFunctions <- nimbleFunctionList(bootStepVirtual)
    for(iNode in seq_along(nodes)){
      bootStepFunctions[[iNode]] <- bootFStep(model, mvEWSamples, mvWSamples, nodes,
                                              iNode, names, saveAll, smoothing, silent) 
    }
  },
  run = function(m = integer(default = 10000)) {
    returnType(double())
    my_initializeModel$run()
    resize(mvWSamples, m)
    resize(mvEWSamples, m)
    threshNum <- ceiling(thresh*m)
    logL <- 0   
    # prevSamp indicates whether resampling took place at the
    # previous time point.
    prevSamp <- 1
    for(iNode in seq_along(bootStepFunctions)) { 
      out <- bootStepFunctions[[iNode]]$run(m,threshNum, prevSamp)
      logL <- logL + out[1]
      prevSamp <- out[2]
      if(logL == -Inf) return(logL)
      if(is.nan(logL)) return(-Inf)
      if(logL == Inf) return(-Inf) 
    }
    return(logL)
  }, where = getLoadingNamespace()
)
