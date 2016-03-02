#!/bin/sh

show_usage() {
	cat 1>&2 <<EOT
Usage: docker run [--rm] -v /path/to/outdir:/out bakudankun/ricty-generator [OPTIONS]
       docker run [--rm] bakudankun/ricty-generator --tarball [OPTIONS] > Ricty.tar.gz
       docker run [--rm] bakudankun/ricty-generator --zipball [OPTIONS] > Ricty.zip
       docker run [--rm] bakudankun/ricty-generator [ -h | --help ]

A nice guy which generate Ricty fonts automatically.

Options:

  --discord-opts=opts      Options for ricty_discord_converter.pe (read Ricty's README for detail)
  --generator-opts=opts    Options for ricty_generator.sh (read Ricty's README for detail)
  -o, --oblique            Create oblique fonts
  --no-os2                 Don't execute os2version_reviser.sh
  --tarball                Vomit .tar.gz archive of generated fonts to stdout
  -h, --help               Show usage
  --zipball                Vomit .zip archive of generated fonts to stdout
EOT
}


# Parse options.

OPT=`getopt -o "oh" -l "tarball,zipball,help,oblique,no-os2,generator-opts:,discord-opts:" -- "$@"`
if [ $? != 0 ]; then show_usage; exit 1; fi

eval set -- "$OPT"

while [ $# -gt 0 ]
do
	case $1 in
		--tarball) tarball=true; zipball=; shift ;;
		--zipball) zipball=true; tarball=; shift ;;
		--generator-opts) shift; generator_opts=$1; shift ;;
		--discord-opts) shift; discord_opts=$1; shift ;;
		-o | --oblique) oblique=true; shift ;;
		--no-os2) no_os2=true; shift ;;
		-h | --help) show_usage; exit 0 ;;
		--) shift; break ;;
		*) show_usage; exit 1 ;;
	esac
done


# Exit if no output method is set.

if [ ! ( "$tarball" -o "$zipball" -o -d /out ) ]; then show_usage; exit 1; fi


cd /Ricty-${RICTY_VERSION}


# Generate Ricty fonts if not exist.

ls Ricty*.ttf >/dev/null 2>&1
if [ $? != 0 ]; then
	eval "./ricty_generator.sh $generator_opts auto" 1>&2
	if [ $? != 0 ]; then
		echo 'ricty_generator.sh returned an error. Exiting...' 1>&2
		exit 1
	fi
	ls Ricty*.ttf >/dev/null 2>&1
	if [ $? != 0 ]; then
		echo 'Failed to generate Ricty. Exiting...' 1>&2
		exit 1
	fi
fi

# Now Ricty*.ttf must be exist.


# Generate Discord fonts if --discord-opts is specified and not already exists.

ls Ricty*Discord-*.ttf >/dev/null 2>&1
if [ $? != 0 -a "$discord_opts" ]; then
	echo 'Generate specified RictyDiscord fonts.' 1>&2
	rm Ricty*Discord*.ttf >/dev/null 2>&1
	eval "fontforge ricty_discord_converter.pe $discord_opts Ricty*.ttf" 1>&2
	if [ $? != 0 ]; then
		echo 'ricty_discord_converter.pe returned an error. Exiting...' 1>&2
		exit 1
	fi
	echo 'Done.' 1>&2
fi


# Generate oblique fonts if --oblique is specified and not already exists.

ls Ricty*Oblique.ttf >/dev/null 2>&1
if [ $? != 0 -a "$oblique" ]; then
	echo 'Create oblique fonts.' 1>&2
	fontforge ./misc/regular2oblique_converter.pe Ricty*.ttf 1>&2
	if [ $? != 0 ]; then
		echo 'regular2oblique_converter.pe returned an error. Exiting...' 1>&2
		exit 1
	fi
	echo 'Done.' 1>&2
fi


# Run os2version_reviser.sh for Windows if --no-os2 isn't set.

if [ ! "$no_os2" ]; then
	for i in Ricty*.ttf
	do
		if [ ! -f $i.bak ]; then
			preos2+=($i)
		fi
	done
	if [ "$prerevise" ]; then
		echo 'Now revise fonts for OS/2 (it may takes a little time).' 1>&2
		./misc/os2version_reviser.sh ${prerevise[@]} 1>&2
		if [ $? = 0 ]; then
			echo 'Done.' 1>&2
		else
			echo 'Failed to revise fonts. The output fonts may have wide spaces.' 1>&2
		fi
	fi
fi


# Output the generated fonts.

if ls Ricty*.ttf >/dev/null 2>&1; then
	if [ -d /out ]; then
		cp -r Ricty*.ttf LICENSE README.md /out
		echo 'Copied the font files. Check the output dir.' 1>&2
	fi
	
	if [ "$tarball" -o "$zipball" ]; then
		outdir="Ricty-v${RICTY_VERSION}"
		mkdir $outdir
		cp -r Ricty*.ttf LICENSE README.md $outdir
		if [ "$tarball" ]; then
			echo 'Now vomit the .tar.gz archive to stdout.' 1>&2
			tar -czf - $outdir
		elif [ "$zipball" ]; then
			echo 'Now vomit the .zip archive to stdout.' 1>&2
			zip -qr - $outdir
		fi
		echo 'Done. Check the redirected file.' 1>&2
	fi
else
	echo 'Huh? What happened?' 1>&2
	exit 1
fi
