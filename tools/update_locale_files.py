#!/usr/bin/env python3
# -*- coding: utf-8 -*-

##########################################################################
##### PUBLIC DOMAIN ######################################################
# This script is released into the public domain via the CC0 dedication.
# See <https://creativecommons.org/publicdomain/zero/1.0/> for details.
##########################################################################

##########################################################################
##### ABOUT THIS SCRIPT ##################################################
# This script updates the translation template files (*.pot) or
# translation files (*.po) of all mods by using the gettext tools.
# It requires you have the 'gettext' software installed on your system.
#
# INVOCATION:
# ./update_locale_files.py [mode]
#
#     where "mode" is either "pot" if you want to update the *.pot files
#     or "po" if you want to update the *.po files. If "mode" is omitted,
#     it defaults to "pot".
##########################################################################



# e-mail address to send problems with the original strings ("msgids") to
MSGID_BUGS_ADDRESS = "no@example.com"
# name of the package
PACKAGE_NAME = "mineclonia"
# version of the package (optional)
PACKAGE_VERSION = None

import os
import re
import sys

# pattern for the 'name' in mod.conf
pattern_name = re.compile(r'^name[ ]*=[ ]*([^ \n]*)')
# file name pattern for gettext translation template files (*.pot)
pattern_pot = re.compile(r'(.*)\.pot$')
# file name pattern for gettext translation files (*.po)
pattern_po = re.compile(r'(.*)\.po$')

def invoke_msgmerge(template_file, mod_folder, modname):
    containing_path = os.path.dirname(template_file)

    po_files = []
    for root, dirs, files in os.walk(os.path.join(mod_folder)):
       for f in files:
          match = pattern_po.match(f)
          if match:
              po_files.append(f)
    if len(po_files) > 0:
        for po_file in po_files:
            po_file = os.path.join("locale", po_file)
            po_file = os.path.join(mod_folder, po_file)
            command = "msgmerge --backup=none -U '"+po_file+"' '"+template_file+"'"
            return_value = os.system(command)
            if return_value != 0:
                print("ERROR: msgmerge invocation returned with "+str(return_value))
                exit(1)

def invoke_xgettext(template_file, mod_folder, modname):
    containing_path = os.path.dirname(template_file)
    lua_files = [os.path.join(mod_folder, "*.lua")]
    for root, dirs, files in os.walk(os.path.join(mod_folder)):
       for dirname in dirs:
           if dirname != "sounds" and dirname != "textures" and dirname != "models" and dirname != "locale" and dirname != "media" and dirname != "schematics":
               lua_path = os.path.join(mod_folder, dirname)
               lua_files.append(os.path.join(lua_path, "*.lua"))

    lua_search_string = " ".join(lua_files)

    package_string = "--package-name='"+PACKAGE_NAME+"'"
    if PACKAGE_VERSION:
        package_string += " --package-version='"+PACKAGE_VERSION+"'"

    command = "xgettext -L lua -kS -kNS -kFS -kNFS -kPS:1,2 -kcore.translate:1c,2 -kcore.translate_n:1c,2,3 -d '"+modname+"' --add-comments='~' -o '"+template_file+"' --from-code=UTF-8 --msgid-bugs-address='"+MSGID_BUGS_ADDRESS+"' "+package_string+" "+lua_search_string

    return_value = os.system(command)
    if return_value != 0:
        print("ERROR: xgettext invocation returned with "+str(return_value))
        exit(1)

def update_locale_template(folder, modname, mode):
    for root, dirs, files in os.walk(os.path.join(folder, 'locale')):
        for name in files:
            code_match = pattern_pot.match(name)
            if code_match == None:
                continue
            fname = os.path.join(root, name)
            if mode == "pot":
                invoke_xgettext(fname, folder, modname)
            elif mode == "po":
                invoke_msgmerge(fname, folder, modname)
            else:
                print("ERROR: invalid locale template mode!")
                exit(1)

def get_modname(folder):
    try:
        with open(os.path.join(folder, "mod.conf"), "r", encoding='utf-8') as mod_conf:
            for line in mod_conf:
                match = pattern_name.match(line)
                if match:
                    return match.group(1)
    except FileNotFoundError:
        if not os.path.isfile(os.path.join(folder, "modpack.txt")):
            folder_name = os.path.basename(folder)
            return folder_name
        else:
            return None
    return None

def update_mod(folder, mode):
    modname = get_modname(folder)
    if modname != None:
       print("Updating '"+modname+"' ...")
       update_locale_template(folder, modname, mode)

def main():
    mode = ""
    if len(sys.argv) >= 2:
        mode = sys.argv[1]
    if mode == "":
        mode = "pot"
    if mode != "po" and mode != "pot":
        print("ERROR: invalid mode specified. Provide either 'po', 'pot' or nothing as command line argument")
        exit(1)

    for modfolder in [f.path for f in os.scandir("./mods") if f.is_dir() and not f.name.startswith('.')]:
        is_modpack = os.path.exists(os.path.join(modfolder, "modpack.txt")) or os.path.exists(os.path.join(modfolder, "modpack.conf"))
        if is_modpack:
            subfolders = [f.path for f in os.scandir(modfolder) if f.is_dir() and not f.name.startswith('.')]
            for subfolder in subfolders:
                update_mod(subfolder, mode)
        else:
            update_mod(modfolder, mode)
    print("All done.")

main()
