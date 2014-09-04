source('loadAllCode.R')

## Notes and examples as we plan to re-write some of the node processing and graph inspection functions

## example of looking at newSetupCode

m1c <- modelCode({ x ~ dnorm(mu, 1); mu ~ dnorm(0, 2)})
m1 <- nimbleModel(m1c)
Cm1 <- compileNimble(m1)

m1mcmcSpec <- MCMCspec(m1)
m1mcmc <- buildMCMC(m1mcmcSpec)
Cm1mcmc <- compileNimble(m1mcmc, project = m1)

## looking inside things:
m1proj <- getNimbleProject(Cm1mcmc)
ls(m1proj)
ls(m1proj$nimbleFunctions) ## the "x_*" and "mu_*" are from the model.  the "nfRefClass_*" are from the mcmc.
ls(m1proj$nfCompInfos) ## these are the comilation information objects
class(m1proj$nfCompInfos[['mu_L2_UID5']]$nfProc)
ls(m1proj$nfCompInfos[['mu_L2_UID5']])
m1proj$nfCompInfos[['mu_L2_UID5']]$nfProc$newSetupCode
m1proj$nfCompInfos[['mu_L2_UID5']]$nfProc$newSetupCodeOneExpr

m1proj$nfCompInfos[['nfRefClass32']]$nfProc$newSetupCode
m1proj$nfCompInfos[['nfRefClass32']]$nfProc$newSetupCodeOneExpr

