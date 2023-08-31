#! /bin/bash
#
# This script creates an animated GIF of an input image that appears to rotate in one direction continuously in a loop.
#
# Example Usages:
#
# ./spin.sh --help
# ./spin.sh Image.png
# /.spin.sh -c Image.png
# /.spin.sh -b '#FFFFFF' Image.png

set -e
SCRIPT_NAME=$0

display_help()
{
    echo "Usage: $SCRIPT_NAME [OPTIONS ...] FILE"
    echo "Create an animated GIF of a static input image in FILE that appears to rotate in one direction continuously in a loop."
    echo
    echo "OPTIONS:"
    echo "  -b, --background HEX, --background=HEX   (OPTIONAL) The color in RGB HEX to fill in the background with if the spin of the image"
    echo "                                                      leaves non-image space on the canvas;  HEX should be numeric and start with '#';"
    echo "                                                      The default color used if not provided is '#00000000' (transparent);"
    echo "                                                      Common choices include: '#000000' (black) or '#FFFFFF' (white)"
    echo "  -c, --counter-clockwise                  (OPTIONAL) Spin the image counter-clockwise instead of clockwise"
    echo "  -h, --help                               (OPTIONAL) Display this help and exit"
}

echo_error()
{
    echo "$1" >&2
}

set_background_color()
{
    if [ -z "$1" ]; then
        echo_error "Error: No value provided for option: '-b'"
        display_help
        exit 1
    elif [ -n "$BACKGROUND_COLOR" ]; then
        echo_error "Error: Duplicate options provided for: '-b'"
        display_help
        exit 1
    fi
    BACKGROUND_COLOR="$1"
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
    if [ -z "$BACKGROUND_COLOR" ]; then
        # Default is transparent
        BACKGROUND_COLOR="#00000000"
    fi

    if [ -z "$IS_CLOCKWISE" ]; then
        IS_CLOCKWISE="true"
    fi
}

validate_inputs()
{
    if [ -z "$FILE" ]; then
        echo_error "Error: No value provided for required input: 'FILE'"
        display_help
        exit 1
    fi

    case "$BACKGROUND_COLOR" in
        \#[0-9A-Fa-f]*) : ;;
        *) echo_error "Error: Invalid HEX provided for option: '-b'"; display_help; exit 1;;
    esac

    check_files
}

check_files()
{
    FILE_LIST="$(find $DIRECTORY -type f -iname $FILE)"
    FILE_COUNT="$(find $DIRECTORY -type f -iname $FILE | wc -l)"

    if [ -z "$FILE_COUNT" ] || [ "$FILE_COUNT" -eq 0 ]; then
        echo_error "Error: No files found to spin!"
        exit 1
    fi

    if [ "$FILE_COUNT" -gt 1 ]; then
        echo_error "Error: Found more than one file to spin!"
        exit 1
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

create_spinning_file()
{
    echo "Starting animated image file creation..."

    # Essentially, we build the "animated image" frame by frame, starting with the original image
    COMMAND="magick convert -background \"$BACKGROUND_COLOR\" -delay 10 -dispose Background $FILE"

    ANGLE_MIN=0
    ANGLE_MAX=360

    if [ "$IS_CLOCKWISE" = "true" ]; then
        ANGLE_DELTA=5
        ANGLE=$(($ANGLE_MIN + $ANGLE_DELTA))
    else
        ANGLE_DELTA=-5
        ANGLE=$(($ANGLE_MAX + $ANGLE_DELTA))
    fi

    # Generate a new frame every DELTA degrees in clockwise or counter-clockwise order
    while [ $ANGLE -gt $ANGLE_MIN ] && [ $ANGLE -lt $ANGLE_MAX ]; do
        COMMAND="$COMMAND \\( -clone 0 -distort SRT $ANGLE \\)"
        ANGLE=$(($ANGLE + $ANGLE_DELTA))
    done

    NEW_FILE="${FILE_NAME}_spinning.gif"
    COMMAND="$COMMAND -loop 0 $NEW_FILE"
    eval "$COMMAND"

    echo "Created new file: $NEW_FILE"
    echo "Animated image file creation complete!"
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
        -b|--background) set_background_color "$2"; shift 2;;
        -c|--counter-clockwise) IS_CLOCKWISE="false"; shift;;
        -h|--help) display_help; exit 0;;

        # Long options with any possible values separated by equal signs (alphabetical order)
        --background=*) set_background_color "${1#*=}"; shift;;

        # Default and error handling options
        -*|--*) echo_error "Error: Unknown option: '$1'"; display_help; exit 1;;
        *) parse_file_name "$1"; shift;;
    esac
done

# Execute desired logic based on inputs
verify_image_magick_installed
set_default_inputs
validate_inputs
create_spinning_file

echo "Execution complete!"
exit 0
