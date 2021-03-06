# $LICENSE
# Copyright 2013-2014 Spotify AB. All rights reserved.
#
# The contents of this file are licensed under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with the
# License. You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

require 'eventmachine'

require 'ffwd/protocol'
require 'ffwd/plugin'
require 'ffwd/logging'

require_relative 'json/connection'

module FFWD::Plugin::JSON
  include FFWD::Plugin
  include FFWD::Logging

  DEFAULT_HOST = "localhost"
  DEFAULT_PORT = 19000
  DEFAULT_PROTOCOL = {"line" => "tcp", "frame" => "udp"}
  DEFAULT_KIND = "line"

  register_plugin "json",
    :description => "A simple JSON protocol implementation",
    :options => [
      FFWD::Plugin.option(
        :kind, :default => DEFAULT_KIND,
        :help => [
          "Kind of protocol to use, valid options are 'frame' and 'line'.",
          "'frame' means that the protocol is frame delimited, " +
          "so each received datagram is received.",
          "'line' means that the protocol is line-delimited, " +
          "each line is assumed to be a JSON object."
        ]),
      FFWD::Plugin.option(
        :protocol, :default => DEFAULT_PROTOCOL,
        :help => [
          "Protocol to use when receiving messages.",
          "When :kind is 'frame', this should be 'udp'."
        ])
    ]

  class LineConnection < FFWD::Plugin::JSON::Connection
    include FFWD::Logging
    include EM::Protocols::LineText2

    def self.plugin_type
      "json_line_in"
    end

    def receive_line data
      receive_json data
    rescue => e
      log.error "Failed to receive JSON: #{data.inspect}: #{e}"
    end
  end

  class FrameConnection < FFWD::Plugin::JSON::Connection
    include FFWD::Logging

    def self.plugin_type
      "json_frame_in"
    end

    def receive_data data
      receive_json data
    rescue => e
      log.error "Failed to receive JSON: #{data.inspect}: #{e}"
    end
  end

  KINDS = {"frame" => FrameConnection, "line" => LineConnection}

  def self.setup_input opts
    opts[:host] ||= DEFAULT_HOST
    opts[:port] ||= DEFAULT_PORT

    kind = (opts[:kind] || DEFAULT_KIND).to_s

    unless connection = KINDS[kind]
      raise "No such protocol kind: #{kind}"
    end

    protocol = FFWD.parse_protocol opts[:protocol] || DEFAULT_PROTOCOL[kind]

    if connection == FrameConnection and protocol != FFWD::UDP
      log.warning "When using :frame kind, you should use the UDP protocol." +
                  " Not #{protocol.family.to_s.upcase}"
    end

    if connection == LineConnection and protocol != FFWD::TCP
      log.warning "When using :line kind, you should use the TCP protocol. " +
                  "Not #{protocol.family.to_s.upcase}"
    end

    protocol.bind opts, log, connection
  end
end
