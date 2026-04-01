#!/bin/sh

# Automatically run the mineclonia version that contains this script in a
# temporary world with the translation dumper mod and copy the resulting
# translation string files into the corresponding source mods.
#
# This script uses ``realpath`` to support being run from anywhere and to
# slightly beautify output. When run from its directory it should also work
# with ``realpath`` replaced by ``echo``. It also uses ``mktemp`` and expects
# symlinks to be supported by the file system of the temporary directory. We
# also assume that the directory name chosen by ``mktemp`` contains no space
# characters.

env >/dev/null 2>&1 which "$1" || (echo mod_translation_updater not found at $1, pass the python script as first argument!; false) || exit 1

# get directory of this script (with trailing slash)
mypath=$(realpath "$0")
mydir=${mypath%generate.sh}

# toplevel mineclonia directory
mcladir=$(realpath "${mydir}../..")

minetest=
parameters=

# search ``minetest`` or ``minetestserver`` executable
#
# First check whether we are inside the ``games`` directory of a minetest
# source build directory, alternatively check for minetest installed in
# ``PATH``. If the executable is ``minetest``, add ``--server`` parameter.
for dir in "${mydir}../../../../bin/" ""; do
	for program in minetest minetestserver; do
		command=$(command -v "${dir}${program}")
		if [ -x "${command}" ]; then
			minetest=$(realpath "${command}")
			if [ "${program}" = "minetest" ]; then
				parameters="${parameters} --server"
			fi
			break 2
		fi
	done
done

if [ -z "${minetest}" ]; then
	echo minetest not found, either move mineclonia to the games directory of a run_in_place build of minetest, or make minetest available in PATH
	exit 1
fi

# prepare temporary directory
tmpdir=$(mktemp -d)
if [ ! -d ${tmpdir} ]; then
	echo could not create temporary directory
	exit 1
fi

# create symlink for the special gameid used by the process to make sure that
# no other installation of mineclonia in the shared or user path is
# accidentally used instead of the one that contains this script
gameid=$(grep '^gameid *= *' "${mydir}world/world.mt" | cut -d = -f 2 | grep -o "[^ ][^ ]*")
ln -s "${mcladir}" "${tmpdir}/${gameid}"

# initialize world in temporary directory
cp -r "${mydir}world.conf" "${mydir}/world" "${tmpdir}"

echo Running ${minetest} to extract complex translation strings in ${tmpdir}...
MINETEST_GAME_PATH="${tmpdir}" "${minetest}" ${parameters} --config "${tmpdir}/world.conf" --world "${tmpdir}/world" --logfile "${tmpdir}/debug.txt" --quiet

# the following only works when ``tmpdir`` contains no space characters
# (which would be written to mod_dirs.txt, too)
if [ ! -f ${tmpdir}/world/mcla_translate/mod_dirs.txt ]; then
	echo Running minetest did not produce any translation files.
	echo The temporary directory has been preserved so the situation can be investigated:
	echo You can delete it by running rm -rf \'${tmpdir}\'
	exit 1
fi

cat ${tmpdir}/world/mcla_translate/mod_dirs.txt |while read f; do
	mod=$(echo $f|cut -d " " -f1)
	file=$(echo $f|cut -d " " -f2)
	cp $tmpdir/world/mcla_translate/$file $mod
done

echo Running $1 on ${mcladir}/mods
"$1" pot #"${mcladir}/mods"
"$1" po #-r "${mcladir}/mods"

cat ${tmpdir}/world/mcla_translate/mod_dirs.txt |while read f; do
	mod=$(echo $f|cut -d " " -f1)
	file=$(echo $f|cut -d " " -f2)
	rm $mod/$file
done

echo Mod translation strings have been extracted and updated. You will now want to create a new commit containing the new translation strings
