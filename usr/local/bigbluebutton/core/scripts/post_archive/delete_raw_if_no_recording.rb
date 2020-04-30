#!/usr/bin/ruby
# encoding: UTF-8

# NOTICE:
# This script requires certain root privileges to delete the raw files.
# It uses sudo as a workaround to be able to delete the files owned by the various other applications.

require "trollop"
require File.expand_path('../../../lib/recordandplayback', __FILE__)

# TODO: what about events in redis?
# TODO: not sure about notes; are they kept in the etherpad?

def delete_audio(meeting_id, audio_dir)
  BigBlueButton.logger.info("Deleting audio #{audio_dir}/#{meeting_id}-*.*")
  audio_files = Dir.glob("#{audio_dir}/#{meeting_id}-*.*")
  if audio_files.empty?
    BigBlueButton.logger.info("No audio found for #{meeting_id}")
    return
  end
  audio_files.each do |audio_file|
    #BigBlueButton.logger.info("sudo rm -f #{audio_file}") # debug output
    system('sudo', 'rm', '-f', "#{audio_file}") || BigBlueButton.logger.warn('Failed to delete audio')
  end
end

def delete_directory(source)
  BigBlueButton.logger.info("Deleting contents of #{source} if present.")
  #BigBlueButton.logger.info("sudo rm -rf #{source}") # debug output
  system('sudo', 'rm', '-rf', "#{source}") || BigBlueButton.logger.warn('Failed to delete directory')
end

####################### START #################################################

opts = Trollop::options do
  opt :meeting_id, "Meeting id to archive", :type => String
end
Trollop::die :meeting_id, "must be provided" if opts[:meeting_id].nil?
meeting_id = opts[:meeting_id]

# requires permissions to write to this path as current user
logger = Logger.new("/var/log/bigbluebutton/post_archive.log", 'weekly' )
logger.level = Logger::INFO
BigBlueButton.logger = logger
BigBlueButton.logger.info("Checking if raw recordings for #{meeting_id} should be deleted.")

config = File.expand_path('../../bigbluebutton.yml', __FILE__)
BigBlueButton.logger.info("Loading configuration #{config}")
props = YAML::load(File.open(config))
recording_dir = props['recording_dir']
archived_files = "#{recording_dir}/raw/#{meeting_id}"

events = Nokogiri::XML(File.open("#{archived_files}/events.xml"))
rec_events = BigBlueButton::Events.get_record_status_events(events)
if not rec_events.length > 0
  BigBlueButton.logger.info("There are no recording marks for #{meeting_id}, deleting the recording.")

  audio_dir = props['raw_audio_src']
  deskshare_dir = props['raw_deskshare_src']
  screenshare_dir = props['raw_screenshare_src']
  presentation_dir = props['raw_presentation_src']
  video_dir = props['raw_video_src']
  kurento_video_dir = props['kurento_video_src']
  kurento_screenshare_dir = props['kurento_screenshare_src']

  # delete the successfully archived files
  #BigBlueButton.logger.info("sudo bbb-record --delete #{meeting_id}") # debug output
  system('sudo', 'bbb-record', '--delete', "#{meeting_id}") || BigBlueButton.logger.warn('Failed to delete local recording')

  # delete the raw captures that might still remain
  delete_audio(meeting_id, audio_dir)
  delete_directory("#{presentation_dir}/#{meeting_id}/#{meeting_id}")
  delete_directory("#{screenshare_dir}/#{meeting_id}")
  delete_directory("#{video_dir}/#{meeting_id}")
  delete_directory("#{kurento_screenshare_dir}/#{meeting_id}")
  delete_directory("#{kurento_video_dir}/#{meeting_id}")
else
  BigBlueButton.logger.info("Found recording marks for #{meeting_id}, keeping the recording.")
end

exit 0

