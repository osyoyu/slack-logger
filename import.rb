require 'json'
require 'zip'
require 'fileutils'
require './lib/db'

def importMessages(channel, messages)
  messages.each do |m|
    m['channel'] = channel[:id]
    insert_message(m)
  end
end

def importChannels(channels)
  Channels.find.delete_many
  Channels.insert_many(channels)
end

def importUsers(users)
  Users.find.delete_many
  Users.insert_many(users)
end

# format of exported file
#
# exported.zip
#
# - channels.json
# - users.json
# - channel/
#     - 2015-01-01.json

exportFile = ARGV[0]

dist = 'tmp/'
begin
  Zip::File.open(exportFile) do |zip|
    zip.each do |entry|
      entry.extract(dist + entry.to_s)
    end
    open(dist + 'channels.json') do |io|
      importChannels(JSON.load(io))
    end
    open(dist + 'users.json') do |io|
      importUsers(JSON.load(io))
    end
    zip.each do |entry|
      # channel/2015-01-01.json
      if !File.directory?(dist + entry.to_s) and entry.to_s.split('/').size > 1
        puts "import #{entry.to_s}"
        channel = Channels.find(name: entry.to_s.split('/')[0]).to_a[0]
        messages = JSON.load(entry.get_input_stream)
        importMessages(channel, messages)
      end
    end
  end
ensure
  FileUtils.rm_r(dist)
end
