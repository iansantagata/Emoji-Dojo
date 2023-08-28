#! /bin/bash
#
# This script rotates image files in their current angle and orientation to a new angle and orientation.
#
# Example Usages:
#
# ./rotate.sh --help

set -e
SCRIPT_NAME=$0

display_help()
{
    echo "Usage: $SCRIPT_NAME [OPTIONS ...] FILE"
    echo "Rotate an input image FILE from its current orientation to a new orientation that is rotated a number of degrees in one direction."
    echo
    echo "Default rotational direction is clockwise the number of degrees provided."
    echo
    echo "OPTIONS:"
    echo "  -d, --degrees VALUE, --degrees=VALUE   (REQUIRED) Rotate the image VALUE number of degrees in one direction"
    echo "  -c, --counter-clockwise                (OPTIONAL) Rotate the image counter-clockwise by DEGREES instead of clockwise"
    echo "  -h, --help                             (OPTIONAL) Display this help and exit"
    echo "  -i, --in-place                         (OPTIONAL) Replace the image FILE with its rotated version"
}

echo_error()
{
    echo "$1" >&2
}

set_degrees()
{
    if [ -z "$1" ]; then
        echo_error "Error: No value provided for option: '-d'"
        display_help
        exit 1
    elif [ -n "$DEGREES" ]; then
        echo_error "Error: Duplicate options provided for: '-d'"
        display_help
        exit 1
    fi
    DEGREES="$1"
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

    if [ -f "$1" ] && [ -n "$FILE" ]; then
        echo_error "Error: More than one FILE was provided: '$FILE' and '$1'"
        display_help
        exit 1
    fi

    # Determine what type of file type this is (regular file is allowed)
    if [ -f "$1" ]; then
        FILE="$(basename "$1")"
        FILE_NAME="$(basename "${1%.*}")"
        EXTENSION="${FILE##*.}"
        DIRECTORY="$(dirname "$1")"
    else
        echo_error "Error: Unrecognized type for FILE: '$1'"
        echo_error
        echo_error "File type must be a regular file"
        display_help
        exit 1
    fi
}

validate_inputs()
{
    if [ -z "$DEGREES" ]; then
        echo_error "Error: No value provided for required option: '-d'"
        display_help
        exit 1
    fi

    if [ -z "$FILE" ]; then
        echo_error "Error: No value provided for required input: 'FILE'"
        display_help
        exit 1
    fi

    check_files
}

set_default_inputs()
{
    if [ -z "$IS_CLOCKWISE" ]; then
        IS_CLOCKWISE="true"
    fi

    if [ -z "$IN_PLACE_ROTATION" ]; then
        IN_PLACE_ROTATION="false"
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

check_files()
{
    FILE_LIST="$(find $DIRECTORY -type f -iname $FILE)"
    FILE_COUNT="$(find $DIRECTORY -type f -iname $FILE | wc -l)"

    if [ -z "$FILE_COUNT" ] || [ "$FILE_COUNT" -eq 0 ]; then
        echo_error "Error: No files found to rotate!"
        exit 1
    fi

    if [ "$FILE_COUNT" -gt 1 ]; then
        echo_error "Error: Found more than one file to rotate!"
        exit 1
    fi
}

create_rotated_file()
{
    if [ "$IS_CLOCKWISE" = "true" ]; then
        DIRECTION="clockwise"
    else
        DIRECTION="counter-clockwise"
        DEGREES="-$DEGREES"
    fi

    echo "Starting image file rotation..."

    if [ "$IN_PLACE_ROTATION" = "true" ]; then
        magick mogrify -rotate $DEGREES $DIRECTORY/$FILE
    else
        NEW_FILE="${FILE_NAME}_rotated.$EXTENSION"
        cp $DIRECTORY/$FILE $DIRECTORY/$NEW_FILE
        magick mogrify -rotate $DEGREES $DIRECTORY/$NEW_FILE
        echo "Created new file: $NEW_FILE"
    fi

    echo "File rotation complete!"
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
        -c|--counter-clockwise) IS_CLOCKWISE="false"; shift;;
        -d|--degrees) set_degrees "$2"; shift 2;;
        -h|--help) display_help; exit 0;;
        -i|--in-place) IN_PLACE_ROTATION="true"; shift;;

        # Long options with any possible values separated by equal signs (alphabetical order)
        --degrees=*) set_degrees "${1#*=}"; shift;;

        # Default and error handling options
        -*|--*) echo_error "Error: Unknown option: '$1'"; display_help; exit 1;;
        *) parse_file_name "$1"; shift;;
    esac
done

# Execute desired logic based on inputs
verify_image_magick_installed
set_default_inputs
validate_inputs
create_rotated_file

echo "Execution complete!"
exit 0
