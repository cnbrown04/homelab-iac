#!/bin/sh
# The run of m4b-merge. One book folder in /media/audiobooks/.merge-inbox
# becomes one chaptered M4B in /media/audiobooks/<author>/<title>.
#
# m4b-merge looks up each book in the API of Audnexus with the ASIN. The ASIN
# comes from the folder name, for example "The Book Name [B012345678]". With
# no ASIN, the tool falls back to the tags and the chapters of the files.
# After a success, the tool moves the audio files to done/, and the script
# moves the leftovers, for example the cover, to done/ too. A book whose
# merge fails stays in the inbox, and the next run tries again.
set -u

INBOX=/media/audiobooks/.merge-inbox
DONE=$INBOX/done
OUT=/media/audiobooks

mkdir -p "$DONE" "$OUT"
status=0

for item in "$INBOX"/*; do
    [ -e "$item" ] || break
    name=$(basename "$item")
    # done/ holds the sources of each finished book, and it never goes to
    # the converter.
    if [ "$name" = "done" ]; then
        continue
    fi

    # A folder that is still in use gets new files. Skip each item that has
    # a file younger than 15 minutes.
    if [ -n "$(find "$item" -mmin -15 -print -quit 2>/dev/null)" ]; then
        echo "Skip $name: a file is less than 15 minutes old."
        continue
    fi

    echo "Convert $name"
    if m4b-merge \
        -i "$item" \
        -o "$OUT" \
        --completed-directory "$DONE" \
        --num-cpus 2 \
        --log-level info
    then
        # The tool moved the audio files to done/. Move the folder with the
        # leftovers, for example covers and log files, to done/ too.
        if [ -d "$item" ]; then
            mv "$item" "$DONE/$name" 2>/dev/null || rm -Rf "$item"
        fi
    else
        echo "Merge of $name failed. It stays in the inbox."
        status=1
    fi
done

exit $status
