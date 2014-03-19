require 'eventmachine'
require 'em-http-request'
require 'bindata'
require 'digest'
require 'net/http'

require_relative 'packets'
require_relative 'packet_handler'

module Kitler
  class KitlerServer < EM::Connection
    def initialize
      @buffer = ""
      @reading_packet = nil
      @handler = PacketHandler.new(self)
    end

    def receive_data data
      @buffer << data
      begin
        while not @buffer.empty?
          if @reading_packet == nil
            id = MCUbyte.read(@buffer)
            @reading_packet = id
            shift_buffer 1
          end

          klass = Kitler::Util.mapping[@reading_packet]
          if klass == nil
            raise "Bad packet id #{@reading_packet}"
          end
 
          packet = klass.read(@buffer)
          shift_buffer packet.num_bytes
          @reading_packet = nil

          @handler.handle(packet)
        end
      rescue IOError => e
        return
      end
    end

    def shift_buffer num = 1
      b = @buffer.bytes.to_a
      b.shift num
      @buffer = b.pack("C*")
    end

    def send_packet packet
      send_data (packet.is_a? Packet) ? packet.with_id : packet.to_s
    end
  end
end
