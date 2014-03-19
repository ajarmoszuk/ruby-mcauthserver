require_relative 'kitler_server'

EventMachine.run {
  EM.error_handler{ |e|
    puts "Error raised during event loop: #{e.message}"
    puts e.backtrace
  }

  EventMachine.start_server "0.0.0.0", 25565, Kitler::KitlerServer
}
