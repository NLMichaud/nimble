
# the format of this list should be as follows:
# the name of the element is the name of the BUGS density
# the first string in each element is the BUGS density definition with the BUGS parameters as the first parameters, in order (the parameter names do NOT need to match the names in the BUGS manual since BUGS does not use parameter names), followed by any alternative parameter names
# the second and subsequent strings in an element are any reparameterizations, with the density name as in R/NIMBLE and the canonical parameter names as used in R's math library (and NIMBLE extensions)
# if R/NIMBLE uses the same parameterization (in the same order) and same density name, the element may simply be the BUGS density definition (e.g., dichisq())
# if R/NIMBLE uses the same parameterization but in a different order, then one should define the reordering as a reparameterization (e.g., dbin())



distributionsInputList <- list(
    
    
    ############################################
    #### univariate distributions, discrete ####
    ############################################
    
    
    dbern   = list(BUGSdist = 'dbern(prob)',
                   Rdist    = 'dbinom(size = 1, prob)',
                   discrete = TRUE,
                   range = c(0, 1),
                   pqAvail = TRUE),
    
    dbin    = list(BUGSdist = 'dbin(prob, size)',
                   Rdist    = 'dbinom(size, prob)',
                   discrete = TRUE,
                   range = c(0, Inf),
                   pqAvail = TRUE,
                   alias   = 'dbinom'),
    
    dcat    = list(BUGSdist = 'dcat(prob)',
                   Rdist    = 'dcat(prob)',
                   types    = c('prob = double(1)'),
                   range    = c(1, Inf),
                   discrete = TRUE),
    
    ## construct used to enforce constraints - 0/1 random variable depending on if cond is TRUE
    dconstraint = list(BUGSdist = 'dconstraint(cond)',
                       range = c(0, 1),
                       discrete = TRUE),

    ## construct used to enforce censoring.
    ## takes values 0,1,...,len(c), depending on which interval t falls into
    dinterval     = list(BUGSdist = 'dinterval(t, c)',
                         types    = c('c = double(1)'),
                         range    = c(0, Inf),
                         discrete = TRUE),

    dnegbin = list(BUGSdist = 'dnegbin(prob, size)',
                   Rdist    = 'dnbinom(size, prob)',
                   discrete = TRUE,
                   range    = c(0, Inf),
                   pqAvail  = TRUE,
                   alias    = 'dnbinom'),
    
    dpois   = list(BUGSdist = 'dpois(lambda)',
                   discrete = TRUE,
                   range    = c(0, Inf),
                   pqAvail = TRUE),
    
    
    ##############################################
    #### univariate distributions, continuous ####
    ##############################################
    
    
    dbeta   = list(BUGSdist = 'dbeta(shape1, shape2, mean, sd)',
                   Rdist    = 'dbeta(shape1 = mean^2*(1-mean)/sd^2-mean, shape2 = mean*(1-mean)^2/sd^2+mean-1)',
                   altParams= c('mean = shape1/(shape1+shape2)', 'sd = sqrt(shape1*shape2/((shape1 + shape2)^2*(shape1+shape2+1)))'),
                   range    = c(0, 1),
                   pqAvail  = TRUE),
    
    dchisq  = list(BUGSdist = 'dchisq(df)',
                   range    = c(0, Inf),
                   pqAvail  = TRUE,
                   alias    = 'dchisqr'),

    ## ddexp   = list('ddexp(location, scale, rate)'),   ## 'ddexp' function not implemented yet?  -DT
    ## provide 'laplace' as alias
    
    dexp    = list(BUGSdist = 'dexp(rate, scale)',
                   Rdist    = 'dexp_nimble(rate = 1/scale)',
                   altParams= 'scale = 1/rate',
                   range    = c(0, Inf),
                   pqAvail = TRUE),
    
    dgamma  = list(BUGSdist = 'dgamma(shape, rate, scale, mean, sd)',
                   Rdist    = c('dgamma(shape, scale = 1/rate)', 'dgamma(shape = mean^2/sd^2, scale = sd^2/mean)'),
                   altParams= c('rate = 1/scale', 'mean = scale*shape', 'sd = scale * sqrt(shape)'),
                   range    = c(0, Inf),
                   pqAvail = TRUE),
    
    ## gen.gamma = list(BUGSdist = 'gen.gamma(r, mu, beta)'),   ## not sure the state of this?  -DT
    
    dlnorm  = list(BUGSdist = 'dlnorm(meanlog, taulog, sdlog, varlog)',
                   Rdist    = c('dlnorm(meanlog, sdlog = 1/sqrt(taulog))',
                       'dlnorm(meanlog, sdlog = sqrt(varlog))'),
                   altParams= c('taulog = sdlog^-2', 'varlog = sdlog^2'),
                   range    = c(0, Inf),
                   pqAvail = TRUE),
    
    dlogis  = list(BUGSdist = 'dlogis(location, rate, scale)',
                   Rdist    = 'dlogis(location, scale = 1/rate)',
                   altParams = 'rate = 1/scale',
                   pqAvail = TRUE),
    
    dnorm   = list(BUGSdist = 'dnorm(mean, tau, sd, var)',
                   Rdist    = c('dnorm(mean, sd = 1/sqrt(tau))', 'dnorm(mean, sd = sqrt(var))'),
                   altParams= c('tau = sd^-2', 'var = sd*sd'),
#                   altParams= c('tau = sd^-2', 'var = sd^2'),
                   pqAvail = TRUE),
    
    ## dpar    = list(BUGSdist = 'dpar(alpha, c)'),   ## not sure the state of this?  -DT
    
    dt      = list(BUGSdist = 'dt(mu, tau, df, sigma, sigma2)',
                   Rdist    = c('dt_nonstandard(df, mu, sigma = 1/sqrt(tau))',
                       'dt_nonstandard(df, mu, sigma = sqrt(sigma2))'),
                   altParams = c('tau = sigma^-2', 'sigma2 = sigma^2'),
                   pqAvail = TRUE),
    
    dunif   = list(BUGSdist = 'dunif(min, max)',
                   pqAvail = TRUE),
    
    dweib   = list(BUGSdist = 'dweib(shape, lambda, scale, rate)',
                   Rdist    = c('dweibull(shape, scale = lambda^(-1/shape))', 'dweibull(shape, scale = 1/rate)'),
                   altParams= c('rate = 1/scale', 'lambda = scale^(-shape)'),
                   range   = c(0, Inf),
                   pqAvail = TRUE,
                   alias = 'dweibull'),
    
    
    ####################################
    #### multivariate distributions ####
    ####################################
    
    
    ddirch  = list(BUGSdist = 'ddirch(alpha)',
                   Rdist    = 'ddirch(alpha)',
                   types    = c('value = double(1)', 'alpha = double(1)'),
                   range    = c(0, 1),
                   alias    = 'ddirich'),
    
    dmnorm  = list(BUGSdist = 'dmnorm(mean, prec, cov, cholesky, prec_param)',
                   Rdist    = c('dmnorm_chol(mean, cholesky = chol(prec), prec_param = 1)', 'dmnorm_chol(mean, cholesky = chol(cov), prec_param = 0)', 'dmnorm_chol(mean, cholesky, prec_param)'),
                   altParams= c('prec = calc_dmnormAltParams(cholesky, prec_param, 1)', 'cov = calc_dmnormAltParams(cholesky, prec_param, 0)'),
                   types    = c('value = double(1)', 'mean = double(1)', 'cholesky = double(2)', 'prec = double(2)', 'cov = double(2)')),
    
    dmulti  = list(BUGSdist = 'dmulti(prob, size)',
                   Rdist    = 'dmulti(size, prob)',
                   types    = c('value = double(1)', 'prob = double(1)'),
                   range    = c(0, Inf),
                   discrete = TRUE,
                   alias    = 'dmultinom'),
    
    dmvt  = list(BUGSdist = 'dmvt(mu, prec, scale, cholesky, df, prec_param)',
                   Rdist    = c('dmvt_chol(mu, cholesky = chol(prec), df = df, prec_param = 1)', 'dmvt_chol(mu, cholesky = chol(scale), df = df, prec_param = 0)', 'dmvt_chol(mu, cholesky, df = df, prec_param)'),
                   ## I think it's okay to use the same altParams function for multivariate normal and t
                   altParams= c('prec = calc_dmnormAltParams(cholesky, prec_param, 1)', 'scale = calc_dmnormAltParams(cholesky, prec_param, 0)'),
                   types    = c('value = double(1)', 'mu = double(1)', 'cholesky = double(2)', 'df = double(0)', 'prec = double(2)', 'scale = double(2)')),
    
    dwish   = list(BUGSdist = 'dwish(R, df, S)',
                   Rdist    = c('dwish_chol(cholesky = chol(R), df, scale_param = 0)', 'dwish_chol(cholesky = chol(S), df, scale_param = 1)'),
                  # altParams = c('R = cholesky', 'S = cholesky'), ##NOT CORRECT. These are placeholders to get other parts working.
                   altParams = c('R = inverse(t(cholesky)%*%cholesky)', 'S = inverse(t(cholesky)%*%cholesky)'),
                   alias    = 'dwishart',
                   types    = c('value = double(2)', 'R = double(2)', 'S = double(2)', 'cholesky = double(2)'))
    # altParams ok here (but still would like back/forwardsolve), because code in altParams only used for R if S was provided by user and vice versa, so don't need 'if'
)


        

