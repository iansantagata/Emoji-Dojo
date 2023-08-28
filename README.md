<!-- Badges -->
[![License](https://img.shields.io/github/license/iansantagata/jamms?label=License&color=yellow)](LICENSE)

# Emoji Dojo

This repository is meant to be a storage space for scripts relevant to manipulating small images (aka emojis) in some way.

Here are some examples:

- Want to take an image like this heart ❤️ and make it shimmer through all colors of the rainbow?  Try [partify.sh](scripts/partify.sh)!
- Want to take an image like this 8-ball 🎱 and make it move to look like it's being shaken?  Try [intensify.sh](scripts/intensify.sh)!
- Want to take an image like this car 🚗 and make it move horizontally to appear like its driving?  Try [train.sh](scripts/train.sh)!
- Want to take an image like this upside-down face 🙃 and rotate it so its right-side up?  Try [rotate.sh](scripts/rotate.sh)!
- Want to take an image like this dizzy face 😵 and make it spin in a circle?  Try [spin.sh](scripts/spin.sh)!
- Want to convert your image file from a `.jpg` to a `.png`?  Try [convert.sh](scripts/convert.sh)!

If there is something missing here that you think could be used, feel free to add an issue or a pull request!

## Usage

Simply clone this repository locally and execute any of the scripts in the [scripts](scripts/) folder.

All scripts in this repository are meant to be run using your shell locally (`sh`, `bash`, `zsh`, `ksh`, etc).

Each script has usage instructions at the top of each file.  More technical details can be found for each `SCRIPT_NAME` by running `scripts/SCRIPT_NAME.sh --help` in your shell when at the root of the cloned repository.

## Dependencies

The scripts in this repository require [Image Magick](https://imagemagick.org/) to function properly.
