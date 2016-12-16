# Intercom Conversationd Exporter

These two Ruby programs gather the Intercom conversations and store
their info in CSV files, and the message data as clean text files.


## Requirements

* A Linux distribution (tested on Ubuntu 16.04.1 LTS, 64-bit)
* Ruby 2 or higher (tested on Ruby 2.3.1)
* curl `sudo apt-get install curl`


## Usage

Write down your API key in the form `API_KEY:SECRET_KEY` in file
`api_key` and place it in this directory.

In your favorite terminal, change to this directory and run:
`./intercom_getlist.rb`.

This program will get the list of IDs and descriptions about all of the
conversations you have on Intercom (tweak the number at the end of the
file, 10 by default).

Once it finishes, a file called `intercom_conversation_list.csv` will be
created in the current directory.

Run `./intercom_getmsgs.rb` and the program will create directories
within the `./messages` folder, each directory's name will be the ID of
a conversation, and inside you will find CSV files with information
about the conversation, and the text of each message stored in a text
file.

Copyright 2016 Filip Dimovski <rexich@riseup.net>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.
