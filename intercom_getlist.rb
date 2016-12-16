#!/usr/bin/env ruby
#  
#  intercom_getlist.rb
#  
#  Component to get a list of conversations, page by page, and then
#  forward them to the component to extract the messages from a given
#  conversation in JSON format, and then export them to a CSV file
#  
#  CSV file specification:
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


class IntercomGetConversationsList
  def initialize(api_key, page)
    raise "No API key provided." if api_key.empty?  # RuntimeError if no API key is provided

    @current_page = page      # Current page we're getting conversations from
    @per_page = 60            # Conversations per page
    @conversations = []       # Array to store current page's conversations' information

    # Get the output of Curl in form of JSON data
    curl_output = `curl -s -X GET 'https://api.intercom.io/conversations?per_page=#{@per_page}&page=#{@current_page}' -u '#{api_key}' -H 'Accept:application/json'`
    #~ puts curl_output        # TESTING: Show me the output of Curl

    # TESTING: Use a file with the cached response to avoid calling the server every time we test this program
    #~ curl_output = File.new("response.txt", "r").read

    # Parse JSON data into a giant hash
    @data = JSON.parse(curl_output)
    #~ puts @data     # TESTING: Let's see if it got the hash parsed properly

    raise "Did not receive a proper Intercom conversation list." unless @data.fetch('type') == 'conversation.list'
    @total_pages ||= @data['pages']['total_pages']    # Set the total number of pages ONCE

    if @current_page > @total_pages
      puts "No more conversations to get, all done. Enjoy. :)"
      exit 0
    end

    @per_page = @data['pages']['per_page']            # Get number of elements per page - what if it's the last page? ;)
  end

  def total_pages
    @total_pages
  end

  def get_conversations
    # Regexp to remove HTML tags from the messages
    re = /<("[^"]*"|'[^']*'|[^'">])*>/

    (0...@per_page).each do |i|
      elem = @data['conversations'][i]

      # Tidy up URL and set to 'no_url' if none is provided
      url = elem['conversation_message']['url']
      if url == nil
        url = "no_url"
      else
        url = url.to_s.gsub(re, '').gsub(/\n+/,' ').squeeze(' ')
      end

      # Tidy up subject and set to 'no_subject' if none is provided
      subject = elem['conversation_message']['subject']
      if subject == nil
        subject = "no_subject"
      else
        subject = subject.to_s.gsub(re, '').gsub(/\n+/,' ').squeeze(' ')
      end

      @conversations[i] = { 'id' => elem['id'],
                            'time' => elem['created_at'],
                            'subject' => subject,
                            'url' => url,
                            'type' => elem['conversation_message']['author']['type'] }
      puts "Page #{@current_page}, conversation no. #{i+1} parsed."
    end
  end

  def write_to_csv
    csv_file_name = "intercom_conversation_list.csv"
    CSV.open(csv_file_name, "a+") do |csv|
      (0...@conversations.length).each do |i|
        conv = @conversations[i]
        id, time, subject, url, type = conv['id'], conv['time'], conv['subject'], conv['url'], conv['type']
        csv << [id, time, subject, url, type]
      end
    end
  puts "Exporting to CSV for page #{@current_page} of #{@total_pages} is complete."
  end
end


# Get the API key from a file
api_key = File.open("api_key", "r").read.chomp!

puts "Getting list of all conversations on Intercom. Working on it..."

rofl = IntercomGetConversationsList.new(api_key, 1)
rofl.get_conversations
rofl.write_to_csv

(2..4).each do |page|          # Or (2..rofl.total_pages)
  rofl = IntercomGetConversationsList.new(api_key, page)
  rofl.get_conversations
  rofl.write_to_csv
end

puts "All done. Conversations list is stored in 'intercom_conversation_list.csv'. Enjoy. :)"
