#!/bin/bash

############## Help function #############
display_help() {
    echo "Usage: $(basename $0) [options...] { filenames, --picker }" 
    echo
    echo "Ingest raw files from a memory card and rename them according to"
    echo "the NIDF standard, for example 'RPN_Party_20230815_1234.NEF'"
    echo
    echo "Parameters:"
    echo "   filenames              List of image files to copy. Any exiftool"
    echo "                          compatible file type will work (NEF/CR2/...) "
    echo "   --picker               Alternatively, use file picker dialog"

    echo 
    echo "Available options:"
    echo "   -a, --author           Author initials, defaults to 'RPN'."
    echo "   -d, --dest             Where to import the files to. Not setting this"
    echo "                          option uses the current folder"
    echo "   -h, --help             Display this help message and exit."
    echo "   -j, --jobcode          Optionally include a session title in the"
    echo "                          filename"
    echo "   --debug                Print debug information instead of executing"
    echo "                          exiftool"
    echo
}

############## Parse options #############
FILES=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -j|--jobcode)
      JOBCODE=$2
      shift # past argument
      shift # past value
      ;;
    -d|--dest)
      DESTINATION=$2
      shift
      shift
      ;;
    -a|--author)
      AUTHOR=$2
      shift 
      shift
      ;;
    -h|--help)
      display_help
      exit 0
      ;;
    --debug)
      DEBUG=1
      LIST_FILES=1
      shift
      ;;
    --list)
      LIST_FILES=1
      shift
      ;;
    --picker)
      USE_PICKER=1
      shift
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      FILES+="$1 "
      shift
      ;;
  esac
done

AUTHOR=${AUTHOR:-'RPN'} # Defaults to me :)

if [[ $USE_PICKER -eq 1 ]]; then
  FILES=$(zenity --file-selection --multiple --separator=' ' 2> /dev/null) # suppress errors
fi

############## Confirm settings #############

echo "--------  Ingest with settings  ---------"
echo "Author:                 $AUTHOR"
echo "Jobcode:                ${JOBCODE:-[none]}"
echo "Destination folder:     ${DESTINATION:-$(pwd)}"
echo "Files:                  $(echo $FILES | wc -w) images found"
echo "-----------------------------------------"

JOBCODE=${JOBCODE:+"${JOBCODE}_"} # Only add underscore if jobcode is used
DESTINATION=${DESTINATION:-"."} # No destination? Use current folder

DATEFORMAT="%Y%m%d"
NAME_SPEC="${DESTINATION}/${AUTHOR}_${JOBCODE}"\${CreateDate}"_\${FileNumber}.%e"

# For debugging
if [[ $LIST_FILES -eq 1 ]]; then
  echo "Filenames: $FILES"
fi

read -p "Ingest with these settings? [y/N] " ANSWER
if [[ $ANSWER == [yY]* ]]; then
    echo "Copying..."
else
    echo "Exiting"
    exit 1
fi

############## Execute command #############
if [[ $DEBUG -eq 0 ]]; then
  exiftool -o . "-FileName<$NAME_SPEC" -d $DATEFORMAT -progress $FILES
else
  echo "Copying to: $NAME_SPEC"
fi
