#!/usr/bin/env ruby
#  
#  intercom_getmsgs.rb
#  
#  Component to take a list of conversations from CSV file, get the
#  complete conversation and all of the messages, store their text as
#  text files for the machine learning module, and store their metadata
#  in a CSV file for analysis and 
#  
#  Input CSV file specification:
#  id, time, subject, url, type
#  
#  Output CSV file specification:
#  id, time, subject, url, type
#  
#  Copyright 2016 Filip Dimovski <rexich@riseup.net>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  

require 'json'
require 'csv'


class IntercomConversationsExporter

  def initialize(api_key, conv_id)
    raise "No API key provided." if api_key.empty?          # RuntimeError if no API key is provided
    raise "No Conversation ID provided." if conv_id.empty?  # RuntimeError if no Conversation ID is provided
    @conv_id = conv_id
    @conv_info = {}
    @messages = []
    @users = {}

    puts "Intercom Conversations Exporter"
    # Output directory - create if necessary
    @output_dir = "messages/#{@conv_id}/"
    Dir.mkdir(@output_dir) unless Dir.exists?(@output_dir)
    puts "Output directory: #{@output_dir}"

    # Get the output of Curl in form of JSON data and parse it into a hash
    print "Getting JSON from Intercom API and parsing it..."
    curl_output = `curl -s -X GET https://api.intercom.io/conversations/#{@conv_id} -u '#{api_key}' -H 'Accept:application/json'`
    @data = JSON.parse(curl_output)       # Parse JSON data into a giant hash
    puts "done."

    # RuntimeError if received data is not an Intercom conversation
    raise "Received data is not an Intercom conversation." unless @data.fetch('type') == 'conversation'

    # Get user and assignee (admin) IDs that are part of the conversation and store them in CSV
    csv_users = @output_dir + "users.csv"
    print "Exporting users to #{csv_users}..."
    CSV.open(csv_users, "w") do |csv|
      ['user', 'assignee'].each do |x|
        csv << [ @data[x]['id'], @data[x]['type'] ]
      end
    end
    puts "done."

    # Get conversation info and store it in CSV
    @conv_info = { 'id' => @data['id'], 'time' => @data['created_at'], 'subject' => @data['conversation_message']['id'] }
    csv_conv = @output_dir + "info.csv"
    print "Exporting conversation info to '#{csv_conv}'..."
    CSV.open(csv_conv, "w") do |csv|
      csv << [ @conv_info['id'], @conv_info['time'], @conv_info['subject'] ]
    end
    puts "done."
  end

  def parse_msg
    # The first message is the subject of the conversation, rest are the comments
    msg_first = @data['conversation_message']
    msg_array = @data['conversation_parts']['conversation_parts']
    #~ msg_total = @data['conversation_parts']['total_count']

    # Regexp to remove HTML tags from the messages
    re = /<("[^"]*"|'[^']*'|[^'">])*>/

    print "Parsing messages from the conversation..."

    # Store the first message with index 0
    @messages[0] = { 'id' => msg_first['id'],
                     'time' => @data['created_at'],
                     'author' => msg_first['author']['id'],
                     'msg' => msg_first['body'].to_s.gsub(re, '').gsub(/\n+/,' ').squeeze(' ') }

    # Skip processing if there are no more than one message (comments)
    if msg_array.empty?
      puts "done."
      return
    end

    # Store the rest of the messages from index 1 onwards
    i = 1
    msg_array.map do |elem|
      # Skip empty messages (notes, change of state, etc.)
      unless elem['body'].to_s.empty?
        @messages[i] = { 'id' => elem['id'],
                         'time' => elem['created_at'],
                         'author' => elem['author']['id'],
                         'msg' => elem['body'].to_s.gsub(re, '').gsub(/\n+/,' ').squeeze(' ') }
        i += 1
      end
    end
    puts "done."
  end

  def store_msg
    # Store each message's text in a separate file, and make a CSV list of their metadata
    puts "Number of messages collected: #{@messages.length}"
    csv_msg = @output_dir + "messages.csv"
    print "Writing messages info in '#{csv_msg}', and messages' text in text files..."
    CSV.open(csv_msg, "a+") do |csv|
      (0...@messages.length).each do |i|
        msg = @messages[i]
        msgfile = "msg_%04d.txt" % i
        csv << [msg['id'], msg['time'], msg['author'], msgfile ]   # Write to CSV
        filename = @output_dir + msgfile
        File.open(filename, "w") { |f| f.write(msg['msg']) }
      end
    puts "done."
    end
  end

end




# Get the API key from a file
api_key = File.open("api_key", "r").read.chomp!

CSV.foreach("intercom_conversation_list.csv", "r") do |row|
  candy = IntercomConversationsExporter.new(api_key, row[0])
  candy.parse_msg
  candy.store_msg
end
