#! /bin/bash
#
# This script converts image files from some input format to some output format.
# It does not overwrite the existing files.
#
# Example Usages:
#
# ./convert.sh jpg png
#
# For a list of all formats supported by your system, run: `magick identify -list format`

# TODO - Tell user if they did not use a valid format (input or output)
# TODO - Handle short and long flags and update example usage (i.e. '-f jpg -t jpg' and '--from=jpg --to=png')
# TODO - Output help menu if user does not provide any arguments (or provides invalid ones)
# TODO - Allow user to pass in file name / slug they wish to search for and convert files with that name
# TODO - Allow user an option to replace in place (and/or delete the old file)
# TODO - Allow user to specify a directory to convert files in that directory

SCRIPT_NAME=$0
NUMBER_OF_ARGS=$#

if [ $NUMBER_OF_ARGS != 2 ]; then
    echo "Incorrect number of arguments passed to script '$SCRIPT_NAME'."
    echo "See '$SCRIPT_NAME' file for more details on usage."
    exit 1
fi

CONVERT_FROM=$1
CONVERT_TO=$2

echo "Attempting to convert files in '$CONVERT_FROM' format to '$CONVERT_TO' format."
magick mogrify -format $CONVERT_TO *.$CONVERT_FROM
echo "Successfully converted files in '$CONVERT_FROM' format to '$CONVERT_TO' format."
exit 0
