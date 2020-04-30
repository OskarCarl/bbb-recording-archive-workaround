# Workaround for inadvertently kept recordings in BigBlueButton

**Note:** I should've properly checked the `bbb-record` script before building the complex solution in the `post_archive` script.
There are multiple redundant deletes and the sudo privileges could be reduced to only the `bbb-record` call.
I currently do not have time to change this in here, so I'll just leave it up.

This is a workaround for BBB [keeping unwanted recordings](https://github.com/bigbluebutton/bigbluebutton/issues/9202) of meetings as a result of Greenlight enabling recordings by default.
In short: after a meeting is closed, it checks if any recordings have been explicitly requested via the button and deletes everything if this is not the case.  
It does not fix the issue; BBB still creates recordings of all meetings if Greenlight is used.
The recordings are just deleted earlier than usual.

There is a WIP Pull Request that addresses this issue properly: [bigbluebutton/greenlight #1296](https://github.com/bigbluebutton/greenlight/pull/1296)

## Background

There is a quick workaround described in the GitHub issue linked above.
However, it requires the recordings to be stored on tmpfs paths.
This causes two issues:
- it may require large amounts of memory
- files may be kept until reboot, which is longer than acceptable in some scenarios

This meant that larger changes would need to be done in the `archive.rb` file.
However, this might cause issues when updating.
Due to this, and to enable retroactive cleaning of existing recordings, I have opted to create a separate script in `post_archive`.

## Disclaimer

This workaround is neither pretty nor complete.
I have next to no experience regarding either Ruby or the internals of BBB.
It may delete too many files or too few.
All I know is that it works as desired on our system in the cases I've tested.  
**Please test this workaround thoroughly before using it in production.**

## Installation

- adapt the sudoers file in `etc/...` if you are not using the default paths
- put sudoers file in `/etc/sudoers.d/` and change its mode to `0440`
    - check it using `visudo -c -f <path_to_file>`!
- put the deletion script in the `post_archive` directory in your BigBlueButton installation
- patch the `archive.rb` in the `scripts/archive` folder
    - make a backup of the `archive.rb`!
    - `patch archive.rb -i archive.rb.patch`
- test the configuration
    - check if files are kept when recordings are requested
    - check if files are delted when the are not
    - you can look at the `archive-<internalMeetingID>.log` and `post_archive.log` files in `/var/log/bigbluebutton`
    - get the internal meeting IDs by watching `bbb-record --watch` when starting and ending meetings

### Why patch the `archive.rb`?

I really didn't want to touch the internals of BBB.
This is why I opted to use a `post_archive` script which cleans the collected and generated files.
However, the script [is not executed](https://github.com/bigbluebutton/bigbluebutton/issues/9342) after _archiving_ is done but rather after _sanity-checking_ is done.
Sanity chekcing is skipped for meetings if no recordings were requested in the interface.

To work around this, the script is now called at the end of archiving.
This may have side effects, however I don't quite fully understand if and when multiple chunks would be created in a meeting.
Consequently I cannot check for this.

### `sudo` privileges?

The script uses the `bbb-record` command, which requires root acces to delete archived files.  
Additionally, the source files are owned by the application that generated them.
To be able to delete these without sudo would be complex, as larger changes on the system would be required.
The sudo permissions are kept as restricive as I could think of.

## Manual retroactive cleaning

The script can be used to retroactively clean the archive files of meetings which were not explicitly requested to be recorded.
Just drop it onto the BBB server and run it.
If you are not using the default configuration you might need to adapt the three variables at the top.

