#! /bin/bash
#
# This script flips image files along one of its axes (horizontal or vertical).
#
# Example Usages:
#
# ./flip.sh --help
# ./flip.sh -v Image.png
# ./flip.sh -o -i Image.png
# ./flip.sh --horizontal --vertical Image.png

set -e
SCRIPT_NAME=$0

display_help()
{
    echo "Usage: $SCRIPT_NAME [OPTIONS ...] FILE"
    echo "Flips an input image FILE along one or both of its axes (horizontal and/or vertical)."
    echo
    echo "At least one axis (horizontal or vertical) to flip over must be provided."
    echo
    echo "OPTIONS:"
    echo "  -h, --help         (OPTIONAL) Display this help and exit"
    echo "  -i, --in-place     (OPTIONAL) Replace the image FILE with its flipped version"
    echo "  -o, --horizontal   (OPTIONAL) Flip the image FILE along its horizontal axis"
    echo "  -v, --vertical     (OPTIONAL) Flip the image FILE along its vertical axis"
}

echo_error()
{
    echo "$1" >&2
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
        FILE_NAME_ROOT="$(basename "${1%.*}")"
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

set_default_inputs()
{
    if [ -z "$IN_PLACE_FLIP" ]; then
        IN_PLACE_FLIP="false"
    fi

    if [ -z "$IS_FLIP_HORIZONTAL" ]; then
        IS_FLIP_HORIZONTAL="false"
    fi

    if [ -z "$IS_FLIP_VERTICAL" ]; then
        IS_FLIP_VERTICAL="false"
    fi
}

validate_inputs()
{
    if [ -z "$FILE" ]; then
        echo_error "Error: No value provided for required input: 'FILE'"
        display_help
        exit 1
    fi

    if [ "$IS_FLIP_HORIZONTAL" != "true" ] && [ "$IS_FLIP_VERTICAL" != "true" ]; then
        echo_error "Error: At least one of the following options must be provided: '-o', '-v'"
        display_help
        exit 1
    fi

    check_files
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
        echo_error "Error: No files found to flip!"
        exit 1
    fi

    if [ "$FILE_COUNT" -gt 1 ]; then
        echo_error "Error: Found more than one file to flip!"
        exit 1
    fi
}

create_flipped_file()
{
    echo "Starting image file flipping..."

    if [ "$IN_PLACE_FLIP" = "true" ]; then
        TARGET_FILE=$FILE
    else
        TARGET_FILE="${FILE_NAME_ROOT}_flipped.$EXTENSION"
        cp $DIRECTORY/$FILE $DIRECTORY/$TARGET_FILE
        echo "Created new file: $TARGET_FILE"
    fi

    if [ "$IS_FLIP_HORIZONTAL" = "true" ]; then
        magick mogrify -flip $DIRECTORY/$TARGET_FILE
    fi

    if [ "$IS_FLIP_VERTICAL" = "true" ]; then
        magick mogrify -flop $DIRECTORY/$TARGET_FILE
    fi

    echo "File flipping complete!"
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
        -o|--horizontal) IS_FLIP_HORIZONTAL="true"; shift;;
        -h|--help) display_help; exit 0;;
        -i|--in-place) IN_PLACE_FLIP="true"; shift;;
        -v|--vertical) IS_FLIP_VERTICAL="true"; shift;;

        # Default and error handling options
        -*|--*) echo_error "Error: Unknown option: '$1'"; display_help; exit 1;;
        *) parse_file_name "$1"; shift;;
    esac
done

# Execute desired logic based on inputs
verify_image_magick_installed
set_default_inputs
validate_inputs
create_flipped_file

echo "Execution complete!"
exit 0
