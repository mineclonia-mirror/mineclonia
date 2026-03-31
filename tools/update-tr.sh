#!/bin/bash

# assumes to be started in mineclonia top level directory and that Luanti's mod
# tools and Wuzzy's translation tools are in PATH

tools/generate_translation_strings/generate.sh mod_translation_updater.py
python tools/update_locale_files.py
