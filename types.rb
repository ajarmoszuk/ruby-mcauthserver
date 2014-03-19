require 'bindata'

module Kitler
  class MCByte < BinData::Int8be; end
  class MCUbyte < BinData::Uint8be; end

  class MCShort < BinData::Int16be; end
  class MCUshort < BinData::Uint16be; end 

  class MCInt < BinData::Int32be; end
  class MCUint < BinData::Uint32be; end

  class MCLong < BinData::Int64be; end
  class MCUlong < BinData::Uint64be; end
  
  class MCType < BinData::Primitive
  end

  class MCString < MCType
    mc_short  :len,  value: lambda { length}
    string :data, read_length: lambda { 2*len}

    def get
      self.data.to_s.force_encoding("utf-16be").encode("utf-8")
    end
    def set(a)
      length = a.to_s.length
      self.data = a.to_s.encode("utf-16be")
    end
  end

  class MCByteArray < MCType
    mc_short :len, value: lambda { (data.length > 0) ? data.length : 0 }
    array :data, type: :mc_ubyte, initial_length: :len
    def get; self.data.to_a.pack("C*").force_encoding("binary"); end
    def set(a)
      if a.instance_of? String
        self.data = a.bytes.to_a
      elsif a.instance_of BinData::Array
        self.data = a
      else
        raise ArgumentError
      end
    end
  end
end