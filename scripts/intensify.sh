#! /bin/bash
#
# This script creates an animated GIF of an input image that appears to shake within the image's frame.
#
# Example Usages:
#
# ./intensify.sh --help
# ./intensify.sh Image.png
# ./intensify.sh -d 20 Image.png
# ./intensify.sh -b '#FFFFFF' Image.png
# ./intensify.sh -d 30 -f 50 -i 1 Image.png

set -e
SCRIPT_NAME=$0

display_help()
{
    echo "Usage: $SCRIPT_NAME [OPTIONS ...] FILE"
    echo "Create an animated GIF of an input image in FILE that appears to shake within the image's frame."
    echo
    echo "OPTIONS:"
    echo "  -b, --background HEX, --background=HEX     (OPTIONAL) The color in RGB HEX to fill in the background with if shifting the image"
    echo "                                                        leaves non-image space on the canvas; HEX is hexadecimal and starts with '#';"
    echo "                                                        The default color used if not provided is '#00000000' (transparent);"
    echo "                                                        Common choices include: '#000000' (black) or '#FFFFFF' (white)"
    echo "  -d, --delay VALUE, --delay=VALUE           (OPTIONAL) Adds a delay of VALUE between frames in the animation;"
    echo "                                                        VALUE is in milliseconds (msec) and must be a positive integer;"
    echo "                                                        Because of GIF rendering limitations, the minimum is 20 milliseconds;"
    echo "                                                        If not used, the default is 50 milliseconds"
    echo "  -f, --frames VALUE, --frames=VALUE         (OPTIONAL) Use the VALUE number of frames when constructing the animation;"
    echo "                                                        More frames will lengthen animation and increase file size;"
    echo "                                                        If not used, the default is 20 frames"
    echo "  -h, --help                                 (OPTIONAL) Display this help and exit"
    echo "  -i, --intensity VALUE, --intensity=VALUE   (OPTIONAL) The maximum intensity VALUE with which to shake the image in the animation;"
    echo "                                                        VALUE is treated as a percentage of the image width and image height;"
    echo "                                                        VALUE should be between 1 and 100 (inclusive) percent;"
    echo "                                                        If not used, the default is 5 percent"
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

set_number_of_frames()
{
    if [ -z "$1" ]; then
        echo_error "Error: No value provided for option: '-f'"
        display_help
        exit 1
    elif [ -n "$NUMBER_OF_FRAMES" ]; then
        echo_error "Error: Duplicate options provided for: '-f'"
        display_help
        exit 1
    fi

    NUMBER_OF_FRAMES="$1"
}

set_max_intensity()
{
    if [ -z "$1" ]; then
        echo_error "Error: No value provided for option: '-i'"
        display_help
        exit 1
    elif [ -n "$MAX_INTENSITY" ]; then
        echo_error "Error: Duplicate options provided for: '-i'"
        display_help
        exit 1
    fi

    MAX_INTENSITY="$1"
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

    if [ -z "$NUMBER_OF_FRAMES" ]; then
        NUMBER_OF_FRAMES=20
    fi

    if [ -z "$MAX_INTENSITY" ]; then
        MAX_INTENSITY=5
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

    case "$DELAY_IN_MSEC" in
        [0-9]*) : ;;
        *) echo_error "Error: Invalid VALUE provided for option: '-d'"; display_help; exit 1;;
    esac

    case "$NUMBER_OF_FRAMES" in
        [0-9]*) : ;;
        *) echo_error "Error: Invalid VALUE provided for option: '-f'"; display_help; exit 1;;
    esac

    case "$MAX_INTENSITY" in
        [0-9]*) : ;;
        *) echo_error "Error: Invalid VALUE provided for option: '-i'"; display_help; exit 1;;
    esac

    if [ "$DELAY_IN_MSEC" -lt 20 ]; then
        echo_error "Error: VALUE provided for flag is below minimum value: '-d'"
        display_help
        exit 1
    fi

    if [ "$MAX_INTENSITY" -le 0 ]; then
        echo_error "Error: VALUE provided for flag is below minimum value: '-i'"
        display_help
        exit 1
    fi

    if [ "$MAX_INTENSITY" -gt 100 ]; then
        echo_error "Error: VALUE provided for flag is above maximum value: '-i'"
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

create_intensified_file()
{
    echo "Starting animated image file creation..."

    # Essentially, we build the "animated image" frame by frame, starting with the original image
    FILE_TOTAL_WIDTH="$(magick identify -format '%[width]' $FILE)"
    FILE_TOTAL_HEIGHT="$(magick identify -format '%[height]' $FILE)"

    WIDTH_SHAKE_IN_PIXELS=$(($MAX_INTENSITY * $FILE_TOTAL_WIDTH / 100))
    HEIGHT_SHAKE_IN_PIXELS=$(($MAX_INTENSITY * $FILE_TOTAL_HEIGHT / 100))

    # Now, start building the command to run to create the animation
    COMMAND="magick $FILE -background \"$BACKGROUND_COLOR\" -delay '${DELAY_IN_MSEC}x1000' -dispose Background"
    FRAMES=1

    while [ "$FRAMES" -lt "$NUMBER_OF_FRAMES" ]; do

        # First, figure out what direction we need to be displacing toward for this frame
        RANDOM_WIDTH_INTENSITY=$(($RANDOM % $WIDTH_SHAKE_IN_PIXELS))
        RANDOM_HEIGHT_INTENSITY=$(($RANDOM % $HEIGHT_SHAKE_IN_PIXELS))

        # 1 or -1 for positive or negative sign purposes
        if [ $(($RANDOM % 2)) -eq 0 ]; then
            RANDOM_X_DIRECTION=1
        else
            RANDOM_X_DIRECTION=-1
        fi

        if [ $(($RANDOM % 2)) -eq 0 ]; then
            RANDOM_Y_DIRECTION=1
        else
            RANDOM_Y_DIRECTION=-1
        fi

        X_DISPLACEMENT=$(($RANDOM_X_DIRECTION * $RANDOM_WIDTH_INTENSITY))
        Y_DISPLACEMENT=$(($RANDOM_Y_DIRECTION * $RANDOM_HEIGHT_INTENSITY))

        # Next, indicate if this displacement is in the positive or negative direction based on conventional X and Y axes
        if [ "$X_DISPLACEMENT" -lt 0 ]; then
            X_SHIFT="$X_DISPLACEMENT" # Will include a negative sign already because the number is negative
        else
            X_SHIFT="+$X_DISPLACEMENT"
        fi

        if [ "$Y_DISPLACEMENT" -lt 0 ]; then
            Y_SHIFT="$Y_DISPLACEMENT" # Will include a negative sign already because the number is negative
        else
            Y_SHIFT="+$Y_DISPLACEMENT"
        fi

        # Finally, create the frame shifted in an X,Y direction and move to the next one
        COMMAND="$COMMAND \\( -clone 0 -distort SRT '0,0 1 0 ${X_SHIFT}${Y_SHIFT}' \\)"
        FRAMES=$(($FRAMES + 1))
    done

    NEW_FILE="${FILE_NAME}_intensifies.gif"
    echo "Creating new file: $NEW_FILE"

    COMMAND="$COMMAND -loop 0 $NEW_FILE"
    eval "$COMMAND"

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
        -d|--delay) set_delay "$2"; shift 2;;
        -f|--frames) set_number_of_frames "$2"; shift 2;;
        -h|--help) display_help; exit 0;;
        -i|--intensity) set_max_intensity "$2"; shift 2;;

        # Long options with any possible values separated by equal signs (alphabetical order)
        --background=*) set_background_color "${1#*=}"; shift;;
        --delay=*) set_delay "${1#*=}"; shift;;
        --frames=*) set_number_of_frames "${1#*=}"; shift;;
        --intensity=*) set_max_intensity "${1#*=}"; shift;;

        # Default and error handling options
        -*|--*) echo_error "Error: Unknown option: '$1'"; display_help; exit 1;;
        *) parse_file_name "$1"; shift;;
    esac
done

# Execute desired logic based on inputs
verify_image_magick_installed
set_default_inputs
validate_inputs
create_intensified_file

echo "Execution complete!"
exit 0
