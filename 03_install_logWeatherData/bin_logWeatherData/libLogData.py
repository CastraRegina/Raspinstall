import os
import fcntl
import datetime
import shutil


#LOGDIRSHM = '/dev/shm/logs'       # in this log-directory the directory YYYYMM will be created.
#                                  # logFilename=<LOGDIRSHM>/YYYYMM/YYYYMMDD-weatherdata.txt   
#LOGDIRHDD = '/home/fk/logs'       # in this log-directory the directory YYYYMM will be created.
#                                  # logFilename=<LOGDIRHDD>/YYYYMM/YYYYMMDD-weatherdata.txt   

def yesterday():
    '''Returns a datetime object of yesterday'''
    return datetime.datetime.now() - datetime.timedelta(days=1)


def mkdirLogDir(logPathAndFilename):
    '''Creates all parent directories of <logPathAndFilename>, if they do not exist'''
    directory = os.path.dirname(logPathAndFilename)
    if os.path.exists(directory):
        return True
    os.makedirs(directory)
    return os.path.exists(directory)


#def getLogDirname(aLogDir, aDateTime = datetime.datetime.now()):
def getLogDirname(aLogDir, aDateTime):
    '''Takes aLOGDIR and the (current) month+day and provides the current whole logDir-pathname.
    Example: $HOME/logs/201909
    '''
    return os.path.join(aLogDir, aDateTime.strftime("%Y%m"))


#def getLogFilename(aLogDir, logMainName, aDateTime = datetime.datetime.now()):
def getLogFilename(aLogDir, logMainName, aDateTime):
    '''Takes aLogDir and provides the (current) whole logFilename.
    Example: $HOME/logs/201909/20190914-<logMainName>
    '''
    logPath = getLogDirname(aLogDir, aDateTime)
    return os.path.join(logPath, aDateTime.strftime("%Y%m%d-" + logMainName))
    

def getCurrentDateTimeISO8601Str(utc = False):
    '''Returns a string of current date&time in ISO8601 format (w/o miliseconds)
    Example: 2019-09-15T10:12:31   
    '''
    #return datetime.datetime.now().isoformat(timespec='seconds')
    if utc :
        dt = datetime.datetime.utcnow().isoformat()
    else:     
        dt = datetime.datetime.now().isoformat()
    return dt[:dt.rfind('.')]

def getCurrentDateTimeYYYYmmddHHMMSSStr(utc = False):
    '''Returns a string of current date&time in YYYYmmdd-HHMMSS format (w/o miliseconds)
    Example: 20190915-101231
    '''
    if utc :
        dt = datetime.datetime.utcnow()
    else:
        dt = datetime.datetime.now()
    return dt.strftime("%Y%m%d-%H%M%S")


def appendToFile(logPathAndFilename, dataStr):
    '''Open <logPathAndFilename> and append a new data-line <dataStr> 
    The file will be locked for writing (i.e. if locked waiting till lock is released). 
    '''
    with open(logPathAndFilename, 'a') as file:
        fcntl.flock(file, fcntl.LOCK_EX)
        file.write(dataStr)
        file.close()


def lockFileForReading(logPathAndFilename):
    '''For debugging: lock a File and return a fileHandle'''
    if not os.path.exists(logPathAndFilename):
        return None
    file = open(logPathAndFilename, 'r')
    fcntl.flock(file, fcntl.LOCK_SH)
    return file


def unlockFile(fileHandle):
    '''For debugging: unlock a locked File'''
    fileHandle.close()
    

#def copyLogFileFromSrcToDest(srcLogDir, destLogDir, logMainName, aDateTime = datetime.datetime.now(), bakLogDir = None):
def copyLogFileFromSrcToDest(srcLogDir, destLogDir, logMainName, aDateTime, bakLogDir = None):
    '''E.g.: Copy log file e.g. from /dev/shm/logs to /home/fk/logs (day specified by aDateTime)'''
    srcFile  = getLogFilename( srcLogDir, logMainName, aDateTime)
    destFile = getLogFilename(destLogDir, logMainName, aDateTime)
     
    def copyFileToDestDir(srcFile, destDir, destFile):
        ok = True
        if not os.path.exists(destDir):
            os.makedirs(destDir)
        if os.path.exists(destDir) and (os.path.exists(srcFile)):
            try:
                fLock = lockFileForReading(srcFile)
                shutil.copy2(srcFile, destFile)
            except Exception as e:
                print('Failed to copy: ' + srcFile + ' --> ' + destFile + ' : ' + str(e))
                ok = False
            finally:
                unlockFile(fLock)
        else:
            print('Failed to copy: srcFile and/or destDir do not exist. ' + srcFile + ' --> ' + destDir)
            ok = False
        return ok
    
    # do the src --> backup copy (if possible):
    if (bakLogDir is not None) and (os.path.exists(destFile)):
        bakFile = getLogFilename(bakLogDir, logMainName, aDateTime) + "_bak" + getCurrentDateTimeYYYYmmddHHMMSSStr(utc = True)
        bakLogDir = getLogDirname(bakLogDir, aDateTime)
        copyFileToDestDir(destFile, bakLogDir, bakFile)
        
    # do the src --> dest copy: 
    destLogDir = getLogDirname(destLogDir, aDateTime)
    return copyFileToDestDir(srcFile, destLogDir, destFile)
    

def main():
    ''' main for testing purpose of this "package" '''
    print("Executing lib for testing... nothing here!!!")

if __name__ == '__main__':
    main()

