# 2014.01.28 This is a grand package unifier: a function that ensures that
# you have the same set of R packages installed across all computers that
# this function may be called from.  Prerequisites: you must keep your R
# packages listed in a synced folder, like Dropbox or SpiderOak Hive.  To
# keep things neat, since those synced folders can get pretty messy, put
# your R package lists in a subfolder of their own, say named syncR.  The
# name of the synced folder ('SpiderOak Hive' or 'Dropbox' is the function
# argument).
syncPacks <- function(syncfolder = "Dropbox") {
    # Get this computer's info
    thisPuter <- Sys.info()
    
    # Find the path of the sync folder. Default spot: in your home folder on a
    # Mac, in Documents on a PC.  If your setup is different, or you need to
    # sync R also on Linux or FreeBSD machines, fiddle with this block of code
    # accordingly:
    root <- paste("/Users", thisPuter["user"], syncfolder, sep = "/")
    if (thisPuter["sysname"] == "Windows") {
        root <- paste("c:/users", thisPuter["user"], "documents", syncfolder, 
                      sep = "/")
    }
    if (!file.exists(root)) {
        stop(paste("Could not find the folder", syncfolder, "on this computer.", 
                   sep = " "))
    }
    # Also if your syncR folder is called something else, fiddle here:
    root <- paste(root, "/syncR", sep = "")
    
    # collect the working directory
    mywd <- getwd()
    # Refresh the packages data set for the computer you're on
    setwd(root)
    fi <- paste(thisPuter["nodename"], ".packs.RData", sep = "")
    packs <- as.data.frame(installed.packages())
    save(packs, file = fi)
    
    # You may already have R package lists from other computers in your sync
    # folder:
    namelist <- dir(getwd())[grep("RData", dir(getwd()))]
    namelist <- gsub(".packs.RData", "", namelist[grep("RData", namelist)])
    namelist <- union(namelist, thisPuter["nodename"])
    
    # Install any packages present on any other computer but missing on this
    # one. 3 steps:
    installMissing <- function(puter) {
        # Step 2: Find what you need to install.
        runMySetdiff <- function(puter) {
            others <- setdiff(namelist, puter)
            # Step 1: return packages on all computers as a list of as many elements as
            # computers.
            getMyPacks <- function() {
                out <- list()
                for (i in namelist) {
                    packz <- paste(i, "packs.Rdata", sep = ".")
                    load(packz)
                    out[[i]] <- as.character(packs$Package)
                }
                return(out)
            }
            mypacks <- getMyPacks()
            # Combine packages from all other computers in one vector.
            others <- unique(unlist(mypacks[others]))
            mine <- unlist(mypacks[[puter]])
            # Return the list of packages missing on this computer.
            toadd <- setdiff(others, mine)
            print(paste(length(toadd), "packages to add.", sep = " "))
            return(toadd)
        }
        needThese <- runMySetdiff(puter)
        if (length(needThese) > 0) {
            install.packages(needThese)
        } else {
            print("good to go.")
        }
    }
    # Step 3: run the installer function for this computer
    installMissing(thisPuter["nodename"])
    
    # Refresh the package list again to reflect any new additions
    packs <- as.data.frame(installed.packages())
    save(packs, file = fi)
    # restore the working directory to whatever it was
    setwd(mywd)
}
# Now just run the whole thing
syncPacks()