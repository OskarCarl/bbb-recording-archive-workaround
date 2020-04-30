#!/bin/bash

ARCHIVE_PATH="/var/bigbluebutton/recording/raw"
SCRIPT_PATH="/usr/local/bigbluebutton/core/scripts/post_archive"
BBB_USER="bigbluebutton"

for archive in "${ARCHIVE_PATH}"/*-*; do
    $SCRIPT_PATH/delete_raw_if_no_recording.rb -m "$(basename $archive)"
done

printf "Done cleaning all existing raw archives.\n"

