require 'openssl'
require 'net/http'

module Kitler
  class PacketHandler
    def initialize(conn)
      @conn = conn
      @username = nil
      @server = nil
      @key = OpenSSL::PKey::RSA.new(2048)
      @ip = Socket.unpack_sockaddr_in(@conn.get_peername)[1]
    end

    def handle(packet)
      if packet.is_a? Handshake
        @username = packet.username
        @server = SecureRandom.hex 8
        @conn.send_packet EncryptionKeyRequest.new server_id:@server, public_key:@key.public_key.to_der, verify_token:"\x00\x00\x00\x00"
      end
      if packet.is_a? EncryptionKeyResponse
        secret = @key.private_decrypt packet.shared_secret
        token = @key.private_decrypt packet.verify_token
        sha = hash ([
          @server,
          secret,
          @key.public_key.to_der
        ])

        check_mcnet(sha)
      end
    end

    def check_mcnet(sha)
      http = EventMachine::HttpRequest.new('http://session.minecraft.net/game/checkserver.jsp').get :query => 
      {'user'=> @username, 'serverId'=> sha}

      http.errback { 
        @conn.send_packet Kick.new reason: '§4Wystapil blad podczas polaczenia z Minecraft.net!' 
        puts "Authenticating #{@username} from #{@ip}, status: error connecting to minecraft.net"
      }
      
      http.callback {
        status = http.response

        if status == "YES"
          msg = "§2Weryfikacja pomyslna, #{@username}"
          status = "OK"
          http = EventMachine::HttpRequest.new("https://freeservers.pl/utils/pingback.php").get :query => {
          'secret' => 'sekretnyphasemacera666kochamyszatanajezusprecz',
          'user' => @username
          }
          http.callback {}
        elsif status == "NO"
          msg = "§4Nie jesteś zalogowany na konto premium!"
          status = "Not premium"
        else
          msg = "§4Minecraft.net nie dziala poprawnie!"
          status = "minecraft.net not working correctly"
        end

        puts "In regards to the authentication of #{@username} from #{@ip}, the current status is: #{status}"
        @conn.send_packet Kick.new reason: msg
      }
    end 

    def hash args
      sha = Digest::SHA1.new
      args.each {|i| sha.update i}
      hash = sha.hexdigest
      i=hash.to_i(16); if i>=(2**159) then i=-(2**160)+i end; hash=i.to_s(16)
    end
  end
end