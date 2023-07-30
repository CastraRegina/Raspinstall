#!/usr/bin/python -u

import serial
import sys
import datetime
import time
import threading
import re
import argparse

import libLogData as lld


#LOGDIRSHM = '/dev/shm/logs'       # in this log-directory the directory YYYYMM will be created.
#                                  # logFilename=<LOGDIRSHM>/YYYYMM/YYYYMMDD-weatherdata.txt   
#LOGDIRHDD = '/home/fk/logs'       # in this log-directory the directory YYYYMM will be created.
#                                  # logFilename=<LOGDIRHDD>/YYYYMM/YYYYMMDD-weatherdata.txt
#LOGMAINNAME = 'weatherdataWDE1.txt'
#SERIALPORT  = '/dev/ttyUSB0'      # serial port of USB-WDE1

threadLock = threading.Lock()
latestDataLine = ""


#S1    2     3     4     5     6     7     8
#1:+12,3;+12,3;  2:+12,3;+12,3;  3:+12,3;+12,3;  4:+12,3;+12,3;  5:+12,3;+12,3;  6:+12,3;+12,3;  7:+12,3;+12,3;  8:+12,3;+12,3;

def round_time(dt, date_delta=datetime.timedelta(minutes=1), to='average'):
    """
    Round a datetime object to a multiple of a timedelta
    dt : datetime.datetime object, default now (datetime.datetime.now())
    dateDelta : timedelta object, we round to a multiple of this, default 1 minute.
    from:  http://stackoverflow.com/questions/3463930/how-to-round-the-minute-of-a-datetime-object-python
    """
    round_to = date_delta.total_seconds()
    seconds = (dt - dt.min).seconds

    if seconds % round_to == 0:
        rounding = (seconds + round_to / 2) // round_to * round_to
    else:
        if to == 'up':
            # // is a floor division, not a comment on following line (like in javascript):
            rounding = (seconds + round_to) // round_to * round_to
        elif to == 'down':
            rounding = seconds // round_to * round_to
        else:
            rounding = (seconds + round_to / 2) // round_to * round_to

    return dt + datetime.timedelta(0, rounding - seconds, -dt.microsecond)


def sleepTillNextFullMinutes(minutes):
    '''Sleep till every full <minutes> is reached. Example: every 5 minutes'''
    now = datetime.datetime.now()
    if now.second == 0:
        now = now + datetime.timedelta(seconds=1)
    nextFullMinute = round_time(now, date_delta=datetime.timedelta(minutes=minutes), to='up')
    while True:
        diff = (nextFullMinute - datetime.datetime.now()).total_seconds()
        if diff <= 0:
            return
        else:
            print("sleeping " + str(diff))
            time.sleep(diff)
    
    
def setLatestDataLine(threadLock, dataLine):
    global latestDataLine
    threadLock.acquire()
    latestDataLine = dataLine.strip() # + "\n"
    threadLock.release()


def getLatestDataLine(threadLock):
    global latestDataLine
    threadLock.acquire()
    dataLine = latestDataLine
    threadLock.release()
    return dataLine


def isDataLineOK(dataLine):
    match = re.search("\$1;1;;(-?\d{0,2},?\d?;){8}(\d{0,2};){8}(-?\d{0,2},?\d?;)(\d{0,2};)(\d{0,3},?\d?;)(\d{0,4};)[01]?;0", dataLine)
    if match:
        return True
    else:
        return False
    #  b'$1;1;;11,3;;14,8;14,2;13,1;13,4;14,3;15,2;67;;80;70;73;70;66;59;13,0;64;3,0;2610;0;0'


def readFromSerial(serialDev, threadLock): # function for thread
    while(True):
        # read line from WDE1
        
        #||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
        line = serialDev.readline().decode('UTF-8')
        #line = input()
        #||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
        
        line = line.strip()
        line = lld.getCurrentDateTimeISO8601Str() + " " + line 
        if isDataLineOK(line):
            print("  >" + line + "< dataline is OK")
            line = "ok  " + line         
        else:
            print("  >" + line + "< dataline with ERROR (not stored)!!!")
            line = "NOK " + line
        setLatestDataLine(threadLock, line)


def logWeatherData(aLogDir, logMainName, serialPort, everyFullMinutes):
    '''Retrieve the weather-data by <serialPort> and save it every <everyFullMinutes>
    Destination for saving: aLogDir, logMainName
    '''
    #  Open serial port:
    #||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
    #serialDev = 0
    #if (True) :
    with serial.Serial(serialPort, 9600) as serialDev:
        if not serialDev.isOpen():
            print("Unable to open serial port %s" % serialPort)
            sys.exit(1)
    #||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
        # Start thread for reading from serial port:
        serialThread = threading.Thread(target=readFromSerial, args=(serialDev, threadLock, ), daemon=True)
        serialThread.start()

        # Start thread for saving periodically:
        while(True):
            logPathAndFilename = lld.getLogFilename(aLogDir, logMainName, datetime.datetime.now())
            if lld.mkdirLogDir(logPathAndFilename) :
                line = getLatestDataLine(threadLock)
                if line != "":
                    line = lld.getCurrentDateTimeISO8601Str(utc = True) + " " + line + '\n'
                    print("writing to file: " + line)
                    lld.appendToFile(logPathAndFilename, line)
                else:
                    print("not saved")
            sleepTillNextFullMinutes(everyFullMinutes)


# MAIN
def main(): 
    # create the top-level parser
    parser = argparse.ArgumentParser(add_help=True, formatter_class=argparse.RawDescriptionHelpFormatter,
                                     description="""
    Program for logging weather data (USB-WDE1).
       python3 logWeatherData.py logWeather    -l /dev/shm/logs -n weatherdataWDE1.txt -s /dev/ttyUSB0 -p 1
       python3 logWeatherData.py copyYesterday -l /dev/shm/logs -n weatherdataWDE1.txt -d /home/fk/logs
       python3 logWeatherData.py copyToday     -l /home/fk/logs -n weatherdataWDE1.txt -d /dev/shm/logs""")

    subparsers = parser.add_subparsers(help='help for subcommand', dest="command")
    
    # create the parser for logWeather command
    parserA = subparsers.add_parser('logWeather', help='log weather data (USB-WDE1)')
    parserA.add_argument('-l', '--logDir'    , type=str, required=True, help="destination directory for log file, e.g. /dev/shm/logs")
    parserA.add_argument('-n', '--logName'   , type=str, required=True, help="log file name, e.g. weatherdataWDE1.txt")
    parserA.add_argument('-s', '--serialPort', type=str, required=True, help="serial port name, e.g. /dev/ttyUSB0")
    parserA.add_argument('-p', '--period'    , type=int, required=True, help="period [minutes], e.g. 1")
    
    # create the parser for copyYesterday command
    parserB = subparsers.add_parser('copyYesterday', help="copy yesterday's log file from logDir to destDir")
    parserB.add_argument('-l', '--logDir'    , type=str, required=True , help="source directory for log file, e.g. /dev/shm/logs")
    parserB.add_argument('-n', '--logName'   , type=str, required=True , help="log file name, e.g. weatherdataWDE1.txt")
    parserB.add_argument('-d', '--destDir'   , type=str, required=True , help="destination directory for log file, e.g. /home/fk/logs")
    parserB.add_argument('-b', '--bakDir'    , type=str, required=False, help="backup directory for log file, e.g. /home/fk/logs/bak")
    
    # create the parser for copyToday command
    parserB = subparsers.add_parser('copyToday', help="copy today's log file from logDir to destDir")
    parserB.add_argument('-l', '--logDir'    , type=str, required=True , help="source directory for log file, e.g. /home/fk/logs")
    parserB.add_argument('-n', '--logName'   , type=str, required=True , help="log file name, e.g. weatherdataWDE1.txt")
    parserB.add_argument('-d', '--destDir'   , type=str, required=True , help="destination directory for log file, e.g. /dev/shm/logs")
    parserB.add_argument('-b', '--bakDir'    , type=str, required=False, help="backup directory for log file, e.g. /home/fk/logs/bak")
    
        
    args = parser.parse_args()
    if not len(sys.argv) > 1:
        parser.print_help()
        sys.exit(1)

    if args.command == 'logWeather' :
        logWeatherData(args.logDir, args.logName, args.serialPort, args.period) 
    elif args.command == 'copyYesterday' :
        if not lld.copyLogFileFromSrcToDest(args.logDir, args.destDir, args.logName, lld.yesterday(), args.bakDir):
            print("error copying!!!")
    elif args.command == 'copyToday' :
        if not lld.copyLogFileFromSrcToDest(args.logDir, args.destDir, args.logName, datetime.datetime.now(), args.bakDir):
            print("error copying!!!") 

if __name__ == '__main__':
    main()


# Szenarios:
#   0:02 : saveLogYesterday.sh
#             python3 logWeatherData.py copyYesterday -l /dev/shm/logs -n weatherdataWDE1.txt -d /home/fk/logs -b /home/fk/logs/bak
#   x:29 : every x:29: saveLogToday.sh
#             python3 logWeatherData.py copyToday     -l /dev/shm/logs -n weatherdataWDE1.txt -d /home/fk/logs -b /home/fk/logs/bak
#   2:30 : reboot
#  (2:31): after-reboot: logWeatherData.sh
#             python3 logWeatherData.py copyToday     -l /home/fk/logs -n weatherdataWDE1.txt -d /dev/shm/logs -b /home/fk/logs/bak 
#             python3 logWeatherData.py logWeather    -l /dev/shm/logs -n weatherdataWDE1.txt -s /dev/ttyUSB0 -p 1
    