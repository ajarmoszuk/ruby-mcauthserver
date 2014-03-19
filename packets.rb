require_relative 'types'

module Kitler
  class Util
    def self.mapping
      Kitler.constants.each_with_object({}) do |constant_name, result|
        klass = Kitler.const_get(constant_name)
        next unless klass.is_a?(Class)
        next unless klass < Packet
        result[klass::Id] = klass
      end
    end
  end

  class Packet < BinData::Record
    Id = -1
    
    def without_id
      to_binary_s
    end

    def with_id
        packet = self.class
        id = packet::Id rescue 0
        MCUbyte.new(id).to_binary_s + to_binary_s
    end
  end

  class Handshake < Packet
    Id = 0x00
    mc_byte :protocol_version
    mc_string :username
    mc_string :host
    mc_int :port
  end
  class EncryptionKeyResponse < Packet
    Id = 0x01
    mc_byte_array :shared_secret
    mc_byte_array :verify_token
  end
  class ServerListPing < Packet
    Id = 0x00
    mc_byte :magic
  end
  class EncryptionKeyRequest < Packet
    Id = 0x01
    mc_string :server_id
    mc_byte_array :public_key
    mc_byte_array :verify_token
  end
  class Kick < Packet
    Id = 0x00
    mc_string :reason
  end
end
