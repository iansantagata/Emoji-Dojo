#! /bin/bash
#
# This script converts image files from a specified input format to a specified output format.
#
# Example Usages:
#
# ./convert.sh --help
# ./convert.sh --from jpg --to png .
# ./convert.sh --from=jpg --to=png --in-place
# ./convert.sh -f jpg -t png path/to/directory
# ./convert.sh -t png -s path/to/file.jpg

# TODO - Tell user if they did not use a valid format (input or output)
# For a list of all formats supported by your system, run: `magick identify -list format`

set -e
SCRIPT_NAME=$0

display_help()
{
    echo "Usage: $SCRIPT_NAME [OPTIONS ...] [FILE]"
    echo "Convert image FILE from its current format to a specified output format."
    echo
    echo "FILE can be an image file or a directory and is the current directory by default."
    echo "When FILE is a directory, converts all images in the directory from a specified"
    echo "input format to a specified output format."
    echo
    echo "All FILEs are preserved by default; FILEs are not modified in-place unless requested."
    echo
    echo "OPTIONS:"
    echo "  -f, --from FORMAT, --from=FORMAT   (OPTIONAL) Image FORMAT to convert images from;"
    echo "                                                REQUIRED when FILE is provided as a directory;"
    echo "                                                Must be omitted when FILE is provided as a regular file"
    echo "  -h, --help                         (OPTIONAL) Display this help and exit"
    echo "  -i, --in-place                     (OPTIONAL) Remove old FILEs after conversion to new type;"
    echo "                                                Simulates an in-place FILE conversion"
    echo "  -s, --skip-prompt                  (OPTIONAL) Skip user confirmation prompt before operating on FILEs"
    echo "  -t, --to FORMAT, --to=FORMAT       (REQUIRED) Image FORMAT to convert images to"
}

echo_error()
{
    echo "$1" >&2
}

set_from_type()
{
    if [ -z "$1" ]; then
        echo_error "Error: No value provided for option: '-f'"
        display_help
        exit 1
    elif [ -n "$CONVERT_FROM" ]; then
        echo_error "Error: Duplicate options provided for: '-f'"
        display_help
        exit 1
    fi
    CONVERT_FROM="$1"
}

set_to_type()
{
    if [ -z "$1" ]; then
        echo_error "Error: No value provided for option: '-t'"
        display_help
        exit 1
    elif [ -n "$CONVERT_TO" ]; then
        echo_error "Error: Duplicate options provided for: '-t'"
        display_help
        exit 1
    fi
    CONVERT_TO="$1"
}

parse_file_name()
{
    if [ -z "$1" ]; then
        echo_error "Error: No FILE provided"
        display_help
        exit 1
    fi

    if [ ! -e "$1" ]; then
        echo_error "Error: FILE '$1' does not exist"
        exit 1
    fi

    if [ -d "$1" ] && [ -n "$DIRECTORY" ]; then
        echo_error "Error: More than one FILE was provided: '$DIRECTORY' and '$1'"
        display_help
        exit 1
    fi

    if [ -f "$1" ] && [ -n "$FILE" ]; then
        echo_error "Error: More than one FILE was provided: '$FILE' and '$1'"
        display_help
        exit 1
    fi

    # Determine what type of file type this is (directory or regular file are allowed)
    if [ -d "$1" ]; then
        DIRECTORY=$1
    elif [ -f "$1" ]; then
        FILE="$(basename "$1")"
        DIRECTORY="$(dirname "$1")"
    else
        echo_error "Error: Unrecognized type for FILE: '$1'"
        echo_error
        echo_error "File type must be a regular file or a directory"
        display_help
        exit 1
    fi
}

validate_inputs()
{
    if [ -z "$CONVERT_FROM" ] && [ -z "$FILE" ]; then
        echo_error "Error: No value provided for required option: '-f'"
        display_help
        exit 1
    fi

    if [ -n "$CONVERT_FROM" ] && [ -n "$FILE" ]; then
        echo_error "Error: Cannot use non-directory FILE '$FILE' with option: '-f'"
        display_help
        exit 1
    fi

    if [ -z "$CONVERT_TO" ]; then
        echo_error "Error: No value provided for required option: '-t'"
        display_help
        exit 1
    fi
}

set_default_inputs()
{
    if [ -z "$DIRECTORY" ] && [ -z "$FILE" ]; then
        DIRECTORY="."
    fi
}

verify_image_magick_installed()
{
    if ! command -v magick >/dev/null 2>&1; then
        echo_error "Error: Image Magick is not installed locally"
        echo_error
        echo_error "$SCRIPT_NAME will not work properly without Image Magick"
        echo_error "See install instructions for Image Magick here: https://imagemagick.org"
        exit 1
    fi
}

ask_for_confirmation()
{
    if [ "$SKIP_CONFIRMATION_PROMPT" != "true" ]; then
        while true; do
            echo
            read -p "Do you wish to continue? (Y/N): " RESPONSE
            case $RESPONSE in
                [Yy]* ) break;;
                [Nn]* ) exit 0;;
                *) echo "Please answer yes (Y) or no (N).";;
            esac
        done
    fi
}

check_files()
{
    if [ -n "$FILE" ]; then
        FILE_LIST="$(find $DIRECTORY -type f -iname $FILE)"
        FILE_COUNT="$(find $DIRECTORY -type f -iname $FILE | wc -l)"
    else
        FILE_LIST="$(find $DIRECTORY -type f -iname "*.$CONVERT_FROM")"
        FILE_COUNT="$(find $DIRECTORY -type f -iname "*.$CONVERT_FROM" | wc -l)"
    fi

    if [ -z "$FILE_COUNT" ] || [ "$FILE_COUNT" -eq 0 ]; then
        echo_error "Error: No files found!"
        exit 1
    fi
}

convert_files()
{
    check_files

    echo "Ready to convert files to '$CONVERT_TO' format:"
    echo "$FILE_LIST"
    echo
    echo "Total file count: $FILE_COUNT"

    ask_for_confirmation

    echo "Starting file conversion..."

    if [ -n "$FILE" ]; then
        magick mogrify -format $CONVERT_TO $FILE
    else
        magick mogrify -format $CONVERT_TO $DIRECTORY/*.$CONVERT_FROM
    fi

    echo "File conversion complete!"
}

delete_preconversion_files()
{
    if [ "$IN_PLACE_CONVERSION" = "true" ]; then
        echo "Starting previous format file deletion..."

        if [ -n "$FILE" ]; then
            rm -f $FILE
        elif [ "$DIRECTORY" = "." ]; then
            rm -f *.$CONVERT_FROM
        else
            rm -f $DIRECTORY/*.$CONVERT_FROM
        fi

        echo "File deletion complete!"
    fi
}

# Show help if no inputs are provided
if [ "$#" -eq 0 ]; then
    display_help
    exit 0
fi

# Iteratively process inputs
while [ "$#" -gt 0 ]; do
    case $1 in
        # Short and long options with any possible values separated by spaces (alphabetical order)
        -f|--from) set_from_type "$2"; shift 2;;
        -h|--help) display_help; exit 0;;
        -i|--in-place) IN_PLACE_CONVERSION="true"; shift;;
        -s|--skip-prompt) SKIP_CONFIRMATION_PROMPT="true"; shift;;
        -t|--to) set_to_type "$2"; shift 2;;

        # Long options with any possible values separated by equal signs (alphabetical order)
        --from=*) set_from_type "${1#*=}"; shift;;
        --to=*) set_to_type "${1#*=}"; shift;;

        -*|--*) echo_error "Error: Unknown option: '$1'"; display_help; exit 1;;
        *) parse_file_name "$1"; shift;;
    esac
done

# Execute desired logic based on inputs
verify_image_magick_installed
validate_inputs
set_default_inputs
convert_files
delete_preconversion_files

echo "Execution complete!"
exit 0
