### Functions for testing math, called from test_math.R
require(testthat)

gen_runFun <- function(input) {
  runFun <- function() {}
  formalsList <- vector('list', length(input$inputDim))
  formalsList <- lapply(input$inputDim, function(x) parse(text = paste0("double(", x, ")"))[[1]])
  names(formalsList) <- paste0('arg', seq_along(input$inputDim))
  formals(runFun) <- formalsList
  tmp <- quote({})
  tmp[[2]] <- input$expr
  tmp[[3]] <- quote(return(out))
  tmp[[4]] <- parse(text = paste0("returnType(double(", input$outputDim, "))"))[[1]]
  body(runFun) <- tmp
  return(runFun)
}

make_input <- function(dim, size = 3, logicalArg) {
  if(!logicalArg) rfun <- rnorm else rfun <- function(n) { rbinom(n, 1, .5) }
  if(dim == 0) return(rfun(1))
  if(dim == 1) return(rfun(size))
  if(dim == 2) return(matrix(rfun(size^2), size))
  stop("not set for dimension greater than 2")
}

test_math <- function(input, verbose = TRUE, size = 3) {
  if(verbose) cat("### Testing", input$name, "###\n")
  runFun <- gen_runFun(input)
  nfGen <- nimbleFunction(
             setup = TRUE,
             run = runFun)
  nfR <- nfGen()
  nfC <- compileNimble(nfR)

  nArgs <- length(input$inputDim)
  logicalArgs <- rep(FALSE, nArgs)
  if("logicalArgs" %in% names(input))
    logicalArgs <- input$logicalArgs
  
  arg1 <- make_input(input$inputDim[1], size = size, logicalArgs[1])
  if(nArgs == 2)
    arg2 <- make_input(input$inputDim[2], size = size, logicalArgs[2])
  if("Rcode" %in% names(input)) {
    eval(input$Rcode)
  } else {
    eval(input$expr)
  }
  if(nArgs == 2) {
    out_nfR = nfR(arg1, arg2)
    out_nfC = nfC(arg1, arg2)
  } else {
    out_nfR = nfR(arg1)
    out_nfC = nfC(arg1)
  }
  attributes(out) <- attributes(out_nfR) <- attributes(out_nfC) <- NULL
  if(is.logical(out)) out <- as.numeric(out)
  if(is.logical(out_nfR)) out_nfR <- as.numeric(out_nfR)
  try(test_that(paste0("Test of math (direct R calc vs. R nimbleFunction): ", input$name), expect_that(out, equals(out_nfR))))
  try(test_that(paste0("Test of math (direct R calc vs. C nimbleFunction): ", input$name), expect_that(out, equals(out_nfC))))
  invisible(NULL)
}

### Function for testing MCMC called from test_mcmc.R


test_mcmc <- function(example, model, data = NULL, inits = NULL,
                      verbose = TRUE, numItsR = 5, numItsC = 1000,
                      basic = TRUE, exactSample = NULL, results = NULL, resultsTolerance = NULL,
                      numItsC_results = numItsC,
                      resampleData = FALSE,
                      topLevelValues = NULL, seed = 0, mcmcControl = NULL, samplers = NULL, removeAllDefaultSamplers = FALSE, 
                      doR = TRUE, doCpp = TRUE) {
  # There are three modes of testing:
  # 1) basic = TRUE: compares R and C MCMC values and, if requested by passing values in 'exactSample', will compare results to actual samples (you'll need to make sure the seed matches what was used to generate those samples)
  # 2) if you pass 'results', it will compare MCMC output to known posterior summaries within tolerance specified in resultsTolerance
  # 3) resampleData = TRUE: runs initial MCMC to get top level nodes then simulates from the rest of the model, including data, to get known parameter values, and fits to the new data, comparing parameter estimates from MCMC with the known parameter values 

  if(!missing(example)) {
    # classic-bugs example specified by name
    dir <- system.file("classic-bugs", package = "nimble")
    vol <- NULL
    if(file.exists(file.path(dir, "vol1", example))) vol <- "vol1"
    if(file.exists(file.path(dir, "vol2", example))) vol <- "vol2"
    if(is.null(vol)) stop("Can't find path to ", example, ".\n")
    dir <- file.path(dir, vol, example)
    if(missing(model)) model <- example
    Rmodel <- readBUGSmodel(model, dir = dir, data = data, inits = inits, useInits = TRUE)
  } else {
    # code, data and inits specified directly where 'model' contains the code
    example = deparse(substitute(model))
    if(missing(model)) stop("Neither BUGS example nor model code supplied.")
    Rmodel <- readBUGSmodel(model, data = data, inits = inits, useInits = TRUE)
  }

  setSampler <- function(var, spec) {
    # remove already defined scalar samplers
    inds <- which(sapply(spec$samplerSpecs, function(x) x$control$targetNode) %in% var[[2]][["targetNode"]])
    spec$removeSamplers(inds, print = FALSE)
    # look for cases where one is adding a blocked sampler and should remove scalar samplers
    inds <- which(sapply(spec$samplerSpecs, function(x)
                         gsub("\\[[0-9]+\\]", "", x$control$targetNode))
                         %in% var[[2]][["targetNodes"]])
    spec$removeSamplers(inds, print = FALSE)
    tmp <- spec$addSampler(var[[1]], control = var[[2]], print = FALSE)
  }

  if(doCpp) {
      Cmodel <- compileNimble(Rmodel)
  }
  if(!is.null(mcmcControl)) mcmcspec <- MCMCspec(Rmodel, control = mcmcControl) else mcmcspec <- MCMCspec(Rmodel)
  if(removeAllDefaultSamplers) mcmcspec$removeSamplers()
  
  if(!is.null(samplers)) {
      sapply(samplers, setSampler, mcmcspec)
      if(verbose) {
          cat("Setting samplers to:\n")
          print(mcmcspec$getSamplers())
      }
  }
  
  vars <- Rmodel$getDependencies(Rmodel$getNodeNames(topOnly = TRUE, stochOnly = TRUE), stochOnly = TRUE, includeData = FALSE, downstream = TRUE)
  vars <- unique(removeIndexing(vars))
  mcmcspec$addMonitors(vars)
  
  Rmcmc <- buildMCMC(mcmcspec)
  if(doCpp) {
      Cmcmc <- compileNimble(Rmcmc, project = Rmodel)
  }
      
  if(basic) {
    ## do short runs and compare R and C MCMC output
      if(doR) {
          set.seed(seed);
          Rmcmc(numItsR)
          RmvSample  <- nfVar(Rmcmc, 'mvSamples')
          R_samples <- as.matrix(RmvSample)
      }
      if(doCpp) {
          set.seed(seed)
          Cmcmc(numItsC)
          CmvSample <- nfVar(Cmcmc, 'mvSamples')    
          C_samples <- as.matrix(CmvSample)
          ## for some reason columns in different order in CmvSample...
          C_subSamples <- C_samples[seq_len(numItsR), attributes(R_samples)$dimnames[[2]], drop = FALSE]
      }

      if(doR & doCpp) {
          context(paste0("testing ", example, " MCMC"))
          try(
              test_that(paste0("test of equality of output from R and C versions of ", example, " MCMC"), {
                  expect_that(R_samples, equals(C_subSamples), info = paste("R and C posterior samples are not equal"))
              })
              )
      }

      if(doCpp) {
          if(!is.null(exactSample)) {
              for(varName in names(exactSample))
                  try(
                      test_that(paste("Test of MCMC result against known samples for", example, ":", varName), {
                          expect_that(round(C_samples[seq_along(exactSample[[varName]]), varName], 8), equals(round(exactSample[[varName]], 8))) })
                      )
          }
      }
      
    summarize_posterior <- function(vals) 
      return(c(mean = mean(vals), sd = sd(vals), quantile(vals, .025), quantile(vals, .975)))

      if(doCpp) {
          if(verbose) {
              start <- round(numItsC / 2) + 1
              try(print(apply(C_samples[start:numItsC, , drop = FALSE], 2, summarize_posterior)))
          }
      }
  }

  ## assume doR and doCpp from here down
  if(!is.null(results)) { 
    
    # do longer run and compare results to inputs given
    set.seed(seed)
    Cmcmc(numItsC_results)
    CmvSample <- nfVar(Cmcmc, 'mvSamples')
    postBurnin <- (round(numItsC_results/2)+1):numItsC_results
    C_samples <- as.matrix(CmvSample)[postBurnin, , drop = FALSE]
    for(metric in names(results)) {
      if(!metric %in% c('mean', 'median', 'sd', 'var', 'cov'))
        stop("Results input should be named list with the names indicating the summary metrics to be assessed, from amongst 'mean', 'median', 'sd', 'var', and 'cov'.")
      if(metric != 'cov') {
        postResult <- apply(C_samples, 2, metric)       
        for(varName in names(results[[metric]])) {
          varName <- gsub("_([0-9]+)", "\\[\\1\\]", varName) # allow users to use theta_1 instead of "theta[1]" in defining their lists
          matched <- grep(varName, dimnames(C_samples)[[2]], fixed = TRUE)
          diff <- abs(postResult[matched] - results[[metric]][[varName]])
          for(ind in seq_along(diff)) {
            strInfo <- ifelse(length(diff) > 1, paste0("[", ind, "]"), "")
            try(
              test_that(paste("Test of MCMC result against known posterior for", example, ":",  metric, "(", varName, strInfo, ")"), {
                expect_that(diff[ind], is_less_than(resultsTolerance[[metric]][[varName]][ind]))
              })
              )
          }
        }
      } else  { # 'cov'
        for(varName in names(results[[metric]])) {
          matched <- grep(varName, dimnames(C_samples)[[2]], fixed = TRUE)
          postResult <- cov(C_samples[ , matched])
           # next bit is on vectorized form of matrix so a bit awkward
          diff <- c(abs(postResult - results[[metric]][[varName]]))
          for(ind in seq_along(diff)) {
            strInfo <- ifelse(length(diff) > 1, paste0("[", ind, "]"), "")
            try(
              test_that(paste("Test of MCMC result against known posterior for", example, ":",  metric, "(", varName, ")", strInfo), {
                expect_that(diff[ind], is_less_than(resultsTolerance[[metric]][[varName]][ind]))
              })
              )
          }
        }
      }
    }
  }
  
  if(resampleData) {
    topNodes <- Rmodel$getNodeNames(topOnly = TRUE, stochOnly = TRUE)
    if(is.null(topLevelValues)) {
      if(is.null(results) && !basic) {
      # need to generate top-level node values so do a basic run
        set.seed(seed)
        Cmcmc(numItsC)
        CmvSample <- nfVar(Cmcmc, 'mvSamples')
        C_samples <- as.matrix(CmvSample)
      }
      postBurnin <- (round(numItsC/2)):numItsC
      topLevelValues <- as.list(apply(C_samples[postBurnin, topNodes, drop = FALSE], 2, mean))
    }
    if(!is.list(topLevelValues)) {
      topLevelValues <- as.list(topLevelValues)
      if(sort(names(topLevelValues)) != sort(topNodes))
        stop("Values not provided for all top level nodes; possible name mismatch")
    }
    sapply(topNodes, function(x) Cmodel[[x]] <- topLevelValues[[x]])
    # check this works as side effect
    nontopNodes <- Rmodel$getDependencies(topNodes, self = FALSE, includeData = TRUE, downstream = TRUE, stochOnly = FALSE)
    nonDataNodes <- Rmodel$getDependencies(topNodes, self = TRUE, includeData = FALSE, downstream = TRUE, stochOnly = TRUE)
    dataVars <- unique(removeIndexing(Rmodel$getDependencies(topNodes, dataOnly = TRUE, downstream = TRUE)))
    set.seed(seed)
    Cmodel$resetData()
    simulate(Cmodel, nontopNodes)

    dataList <- list()
    for(var in dataVars) {
      dataList[[var]] <- values(Cmodel, var)
      if(Cmodel$modelDef$varInfo[[var]]$nDim > 1)
        dim(dataList[[var]]) <- Cmodel$modelDef$varInfo[[var]]$maxs
    }
    Cmodel$setData(dataList)

    trueVals <- values(Cmodel, nonDataNodes)
    names(trueVals) <- nonDataNodes
    set.seed(seed)
    Cmcmc(numItsC_results)
    CmvSample <- nfVar(Cmcmc, 'mvSamples')
    
    postBurnin <- (round(numItsC_results/2)):numItsC
    C_samples <- as.matrix(CmvSample)[postBurnin, nonDataNodes, drop = FALSE]
    interval <- apply(C_samples, 2, quantile, c(.025, .975))
    covered <- trueVals <= interval[2, ] & trueVals >= interval[1, ]
    coverage <- sum(covered) / length(nonDataNodes)
    tolerance <- 0.1
    if(length(nonDataNodes) >= 20) tolerance <- 0.04
    if(verbose) 
      cat("Coverage for model", example, "is", coverage*100, "%.\n")
    miscoverage <- abs(coverage - 0.95)
    try(
      test_that(paste("Test of MCMC coverage on known parameter values for:", example), {
                expect_that(miscoverage, is_less_than(tolerance))
              })
      )
    if(miscoverage > tolerance || verbose) {
      cat("True values with 95% posterior interval:\n")
      print(cbind(trueVals, t(interval), covered))
    }
  }
}