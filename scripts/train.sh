#! /bin/bash
#
# This script creates an animated GIF of an input image that appears to move from one side of the image
# across to the opposite side repeatedly in a loop, like a train or a Conga line.
#
# Example Usages:
#
# ./train.sh --help
# ./train.sh Image.png
# ./train.sh -d 20 Image.png
# ./train.sh -f 50 Image.png
# ./train.sh -m UP Image.png

set -e
SCRIPT_NAME=$0

display_help()
{
    echo "Usage: $SCRIPT_NAME [OPTIONS ...] FILE"
    echo "Create an animated GIF of an input image in FILE that appears to move from one side of the image across to the opposite side repeatedly in a loop, like a train or a Conga line."
    echo
    echo "OPTIONS:"
    echo "  -d, --delay VALUE, --delay=VALUE             (OPTIONAL) Adds a delay of VALUE between frames in the animation;"
    echo "                                                          VALUE is in milliseconds (msec) and must be a positive integer;"
    echo "                                                          Because of GIF rendering limitations, the minimum is 20 milliseconds;"
    echo "                                                          If not used, the default is 50 milliseconds"
    echo "  -f, --min-frames VALUE, --min-frames=VALUE   (OPTIONAL) Use at least VALUE number of frames when constructing the animation;"
    echo "                                                          More frames will be smoother but will increase file size;"
    echo "                                                          Fewer frames will increase speed of the animation but may be jittery;"
    echo "                                                          If not used, the default is 20 frames minimum"
    echo "  -h, --help                                   (OPTIONAL) Display this help and exit"
    echo "  -m, --move DIRECTION, --move=DIRECTION       (OPTIONAL) The DIRECTION for the animated image to appear to move;"
    echo "                                                          DIRECTION can be UP, DOWN, LEFT, or RIGHT;"
    echo "                                                          If not used, the default is RIGHT"
}

echo_error()
{
    echo "$1" >&2
}

set_movement_direction()
{
    if [ -z "$1" ]; then
        echo_error "Error: No value provided for option: '-d'"
        display_help
        exit 1
    fi

    if [ -n "$UPWARD" ] || [ -n "$DOWNWARD" ] || [ -n "$LEFTWARD" ] || [ -n "$RIGHTWARD" ]; then
        echo_error "Error: Duplicate options provided for: '-d'"
        display_help
        exit 1
    fi

    # Case insensitive values (e.g. 'UP' / 'Up' / 'uP' / 'up' are equivalent)
    case "$1" in
        [Uu][Pp]) UPWARD="true";;
        [Dd][Oo][Ww][Nn]) DOWNWARD="true";;
        [Ll][Ee][Ff][Tt]) LEFTWARD="true";;
        [Rr][Ii][Gg][Hh][Tt]) RIGHTWARD="true";;
        *) echo_error "Error: Unknown value for option '-d': '$1'"; display_help; exit 1;;
    esac
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

set_minimum_number_of_frames()
{
    if [ -z "$1" ]; then
        echo_error "Error: No value provided for option: '-f'"
        display_help
        exit 1
    elif [ -n "$MIN_NUMBER_OF_FRAMES" ]; then
        echo_error "Error: Duplicate options provided for: '-f'"
        display_help
        exit 1
    fi

    MIN_NUMBER_OF_FRAMES="$1"
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
    if [ -z "$UPWARD" ] && [ -z "$DOWNWARD" ] && [ -z "$LEFTWARD" ] && [ -z "$RIGHTWARD" ]; then
        RIGHTWARD="true"
    fi

    if [ -z "$UPWARD" ]; then
        UPWARD="false"
    fi

    if [ -z "$DOWNWARD" ]; then
        DOWNWARD="false"
    fi

    if [ -z "$LEFTWARD" ]; then
        LEFTWARD="false"
    fi

    if [ -z "$RIGHTWARD" ]; then
        RIGHTWARD="false"
    fi

    if [ -z "$DELAY_IN_MSEC" ]; then
        DELAY_IN_MSEC=50
    fi

    if [ -z "$MIN_NUMBER_OF_FRAMES" ]; then
        MIN_NUMBER_OF_FRAMES=20
    fi
}

validate_inputs()
{
    if [ -z "$FILE" ]; then
        echo_error "Error: No value provided for required input: 'FILE'"
        display_help
        exit 1
    fi

    case "$DELAY_IN_MSEC" in
        [0-9]*) : ;;
        *) echo_error "Error: Invalid VALUE provided for option: '-d'"; display_help; exit 1;;
    esac

    case "$MIN_NUMBER_OF_FRAMES" in
        [0-9]*) : ;;
        *) echo_error "Error: Invalid VALUE provided for option: '-f'"; display_help; exit 1;;
    esac

    if [ "$DELAY_IN_MSEC" -lt 20 ]; then
        echo_error "Error: Value provided for flag is below minimum value: '-d'"
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

create_train_file()
{
    echo "Starting animated image file creation..."

    # Essentially, we build the "animated image" frame by frame, starting with the original image
    FILE_TOTAL_WIDTH="$(magick identify -format '%[width]' $FILE)"
    FILE_TOTAL_HEIGHT="$(magick identify -format '%[height]' $FILE)"

    # First, we want to figure out the increment to use to get the minimum number of frames
    WIDTH_INCREMENT=$(($FILE_TOTAL_WIDTH / $MIN_NUMBER_OF_FRAMES))
    HEIGHT_INCREMENT=$(($FILE_TOTAL_HEIGHT / $MIN_NUMBER_OF_FRAMES))

    # Since the increment values are truncated (using floor or integer division), we want to calculate actual expected number of frames
    WIDTH_FRAMES=$(($FILE_TOTAL_WIDTH / $WIDTH_INCREMENT))
    HEIGHT_FRAMES=$(($FILE_TOTAL_HEIGHT / $HEIGHT_INCREMENT))

    # Finally, choose the total number of frames to use based on which direction the animation is to move
    if [ "$UPWARD" = "true" ] || [ "$DOWNWARD" = "true" ]; then
        TOTAL_NUMBER_OF_FRAMES=$HEIGHT_FRAMES
    else
        TOTAL_NUMBER_OF_FRAMES=$WIDTH_FRAMES
    fi

    # Now, start building the command to run to create the animation
    COMMAND="magick -delay '${DELAY_IN_MSEC}x1000' -dispose Background $FILE"

    X_DISPLACEMENT=0
    Y_DISPLACEMENT=0
    FRAMES=1

    # Generate a new frame every INCREMENT pixels
    while [ "$FRAMES" -lt "$TOTAL_NUMBER_OF_FRAMES" ]; do

        # First, figure out what direction we need to be displacing toward
        if [ "$DOWNWARD" = "true" ]; then
            Y_DISPLACEMENT=$(($Y_DISPLACEMENT + $HEIGHT_INCREMENT))
        elif [ "$UPWARD" = "true" ]; then
            Y_DISPLACEMENT=$(($Y_DISPLACEMENT - $HEIGHT_INCREMENT))
        elif [ "$RIGHTWARD" = "true" ]; then
            X_DISPLACEMENT=$(($X_DISPLACEMENT + $WIDTH_INCREMENT))
        elif [ "$LEFTWARD" = "true" ]; then
            X_DISPLACEMENT=$(($X_DISPLACEMENT - $WIDTH_INCREMENT))
        fi

        # Next, indicate if this displacement is in the positive or negative direction based on conventional X and Y axes
        if [ "$X_DISPLACEMENT" -lt 0 ]; then
            X_ROLL="$X_DISPLACEMENT" # Will include a negative sign already because the number is negative
        else
            X_ROLL="+$X_DISPLACEMENT"
        fi

        if [ "$Y_DISPLACEMENT" -lt 0 ]; then
            Y_ROLL="$Y_DISPLACEMENT" # Will include a negative sign already because the number is negative
        else
            Y_ROLL="+$Y_DISPLACEMENT"
        fi

        # Finally, create the frame and move to the next one
        COMMAND="$COMMAND \\( -clone 0 -roll ${X_ROLL}${Y_ROLL} \\)"
        FRAMES=$(($FRAMES + 1))
    done

    NEW_FILE="${FILE_NAME}_train.gif"
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
        -d|--delay) set_delay "$2"; shift 2;;
        -f|--min-frames) set_minimum_number_of_frames "$2"; shift 2;;
        -h|--help) display_help; exit 0;;
        -m|--move) set_movement_direction "$2"; shift 2;;

        # Long options with any possible values separated by equal signs (alphabetical order)
        --delay=*) set_delay "${1#*=}"; shift;;
        --min-frames=*) set_minimum_number_of_frames "${1#*=}"; shift;;
        --move=*) set_movement_direction "${1#*=}"; shift;;

        # Default and error handling options
        -*|--*) echo_error "Error: Unknown option: '$1'"; display_help; exit 1;;
        *) parse_file_name "$1"; shift;;
    esac
done

# Execute desired logic based on inputs
verify_image_magick_installed
set_default_inputs
validate_inputs
create_train_file

echo "Execution complete!"
exit 0
