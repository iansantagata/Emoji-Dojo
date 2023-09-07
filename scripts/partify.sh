#! /bin/bash
#
# This script creates an animated GIF of an input image that appears to change colors in a gradient
# to every color of the rainbow.
#
# Example Usages:
#
# ./partify.sh --help

set -e
SCRIPT_NAME=$0

display_help()
{
    echo "Usage: $SCRIPT_NAME [OPTIONS ...] FILE"
    echo "Create an animated GIF of an input image in FILE that appears to change colors in a gradient to every color of the rainbow."
    echo
    echo "OPTIONS:"
    echo "  -b, --background HEX, --background=HEX     (OPTIONAL) The color in RGB HEX to fill in the background with as part of partifying;"
    echo "                                                        HEX is hexadecimal and starts with '#';"
    echo "                                                        The default color used if not provided is '#00000000' (transparent);"
    echo "                                                        Common choices include: '#000000' (black) or '#FFFFFF' (white)"
    echo "  -c, --color HEX, --color=HEX               (OPTIONAL) The color in RGB HEX to replace with party colors in the animated image;"
    echo "                                                        HEX is a hexadecimal and starts with '#';"
    echo "                                                        The default color used if not provided is '#000000' (black);"
    echo "                                                        Common choices include: '#00000000' (transparent) or '#FFFFFF' (white)"
    echo "  -d, --delay VALUE, --delay=VALUE           (OPTIONAL) Adds a delay of VALUE between frames in the animation;"
    echo "                                                        VALUE is in milliseconds (msec) and must be a positive integer;"
    echo "                                                        Because of GIF rendering limitations, the minimum is 20 milliseconds;"
    echo "                                                        If not used, the default is 50 milliseconds"
    echo "  -f, --fuzz VALUE, --fuzz=VALUE             (OPTIONAL) A percent VALUE to enable a fuzzy match against the target color;"
    echo "                                                        VALUE should be between 0 and 100 (inclusive) percent;"
    echo "                                                        If a VALUE of 0 is used, only exactly the same colors will match;"
    echo "                                                        If not used, the default is 10 (percent)"
    echo "  -h, --help                                 (OPTIONAL) Display this help and exit"
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

set_replacement_color()
{
    if [ -z "$1" ]; then
        echo_error "Error: No value provided for option: '-c'"
        display_help
        exit 1
    elif [ -n "$REPLACEMENT_COLOR" ]; then
        echo_error "Error: Duplicate options provided for: '-c'"
        display_help
        exit 1
    fi

    REPLACEMENT_COLOR="$1"
}

set_delay()
{
    if [ -z "$1" ]; then
        echo_error "Error: No value provided for option: '-d'"
        display_help
        exit 1
    elif [ -n "$DELAY_IN_MSEC" ]; then
        echo_error "Error: Duplicate options provided for: '-d'"
        display_help
        exit 1
    fi

    DELAY_IN_MSEC="$1"
}

set_fuzz()
{
    if [ -z "$1" ]; then
        echo_error "Error: No value provided for option: '-f'"
        display_help
        exit 1
    elif [ -n "$REPLACEMENT_FUZZ_PERCENT" ]; then
        echo_error "Error: Duplicate options provided for: '-f'"
        display_help
        exit 1
    fi

    REPLACEMENT_FUZZ_PERCENT="$1"
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

    if [ -z "$DELAY_IN_MSEC" ]; then
        DELAY_IN_MSEC=50
    fi

    if [ -z "$REPLACEMENT_COLOR" ]; then
        # Default is black
        REPLACEMENT_COLOR="#000000"
    fi

    if [ -z "$REPLACEMENT_FUZZ_PERCENT" ]; then
        REPLACEMENT_FUZZ_PERCENT=10
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

    case "$REPLACEMENT_COLOR" in
        \#[0-9A-Fa-f]*) : ;;
        *) echo_error "Error: Invalid HEX provided for option: '-c'"; display_help; exit 1;;
    esac

    case "$DELAY_IN_MSEC" in
        [0-9]*) : ;;
        *) echo_error "Error: Invalid VALUE provided for option: '-d'"; display_help; exit 1;;
    esac

    if [ "$DELAY_IN_MSEC" -lt 20 ]; then
        echo_error "Error: VALUE provided for flag is below minimum value: '-d'"
        display_help
        exit 1
    fi

    check_files
}

check_files()
{
    FILE_LIST="$(find $DIRECTORY -type f -iname $FILE)"
    FILE_COUNT="$(find $DIRECTORY -type f -iname $FILE | wc -l)"

    if [ -z "$FILE_COUNT" ] || [ "$FILE_COUNT" -eq 0 ]; then
        echo_error "Error: No files found to animate!"
        exit 1
    fi

    if [ "$FILE_COUNT" -gt 1 ]; then
        echo_error "Error: Found more than one file to animate!"
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

create_partified_file()
{
    echo "Starting animated image file creation..."

    # Essentially, we build the "animated image" frame by frame, starting with the original image
    # Start building the command to run to create the animation
    COMMAND="magick $DIRECTORY/$FILE -background \"$BACKGROUND_COLOR\" -delay '${DELAY_IN_MSEC}x1000' -dispose Background"
    FRAMES=1

    # Create an array of the party colors
    PARTY_COLORS[0]="#FF6B6B"
    PARTY_COLORS[1]="#FF6BB5"
    PARTY_COLORS[2]="#FF81FF"
    PARTY_COLORS[3]="#D081FF"
    PARTY_COLORS[4]="#81ACFF"
    PARTY_COLORS[5]="#81FFFF"
    PARTY_COLORS[6]="#81FF81"
    PARTY_COLORS[7]="#FFD081"
    PARTY_COLORS[8]="#FF8181"
    COLOR_COUNT=${#PARTY_COLORS[@]}

    # Want to loop through twice to ensure we get a smooth GIF between all frames
    NUMBER_OF_FRAMES=$(($COLOR_COUNT * 2))

    while [ "$FRAMES" -lt "$NUMBER_OF_FRAMES" ]; do

        # Figure out what color to use for this frame
        FRAME_INDEX=$(($FRAMES - 1))
        FRAME_COLOR=${PARTY_COLORS[$(($FRAME_INDEX % $COLOR_COUNT))]}

        # Create the frame by replacing the target color of the original frame with one of the party colors
        COMMAND="$COMMAND \\( -clone 0 -fill '$FRAME_COLOR' -opaque '$REPLACEMENT_COLOR' -fuzz $REPLACEMENT_FUZZ_PERCENT% \\)"

        FRAMES=$(($FRAMES + 1))
    done

    NEW_FILE="${FILE_NAME}_party.gif"
    echo "Creating new file: $NEW_FILE"

    COMMAND="$COMMAND -loop 0 $DIRECTORY/$NEW_FILE"
    eval "$COMMAND"

    # For some reason, the first two frames of the image retain the similarity to the reference image rather than being partified
    # We can remove the first iteration of frames since there should be two from the algorithm above to address this issue
    strip_first_iteration

    echo "Animated image file creation complete!"
}

strip_first_iteration()
{
    # Split the GIF into temporary files, one per each frame
    TEMP_FILE_FORMAT="temp_%03d.miff"
    magick $NEW_FILE +adjoin $DIRECTORY/$TEMP_FILE_FORMAT
    TEMP_FILE_INDEX=0

    # Remove the first set of frames by deleting the first set of temporary files
    while [ "$TEMP_FILE_INDEX" -lt "$COLOR_COUNT" ]; do
        printf -v PADDED_TEMP_FILE_INDEX "%03d" $TEMP_FILE_INDEX
        rm $DIRECTORY/temp_${PADDED_TEMP_FILE_INDEX}.miff

        TEMP_FILE_INDEX=$(($TEMP_FILE_INDEX + 1))
    done

    # Without the first set of frames (files), reconstruct the GIF to ensure the loop is party colored appropriately
    TEMP_FILES_FOUND=$(ls $DIRECTORY/temp_*.miff -1 | tr '\n' ' ')
    COMMAND="magick $TEMP_FILES_FOUND -background \"$BACKGROUND_COLOR\" -delay '${DELAY_IN_MSEC}x1000' -dispose Background -loop 0 $DIRECTORY/$NEW_FILE"
    eval "$COMMAND"

    # Finally, remove the remaining temporary files that were created
    rm $DIRECTORY/temp_*.miff
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
        -c|--color) set_replacement_color "$2"; shift 2;;
        -d|--delay) set_delay "$2"; shift 2;;
        -f|--fuzz) set_fuzz "$2"; shift 2;;
        -h|--help) display_help; exit 0;;

        # Long options with any possible values separated by equal signs (alphabetical order)
        --background=*) set_background_color "${1#*=}"; shift;;
        --color=*) set_replacement_color "${1#*=}"; shift;;
        --delay=*) set_delay "${1#*=}"; shift;;
        --fuzz=*) set_fuzz "${1#*=}"; shift;;

        # Default and error handling options
        -*|--*) echo_error "Error: Unknown option: '$1'"; display_help; exit 1;;
        *) parse_file_name "$1"; shift;;
    esac
done

# Execute desired logic based on inputs
verify_image_magick_installed
set_default_inputs
validate_inputs
create_partified_file

echo "Execution complete!"
exit 0
