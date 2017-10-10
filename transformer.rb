#!/usr/bin/env ruby
require 'nats/client'
require 'rubygems'
require 'json'

pathToToml = ARGV[0]
sid = 0

NATS.start do

  # begin

  # Simple Subscriber
  sid = NATS.subscribe('router.register') {|msg|
    puts "Msg received : '#{msg}'"
    routeMsg = JSON.parse(msg)
    puts "dest IP: '#{routeMsg["host"]}'"
    puts "dest Port: '#{routeMsg["port"]}'"
    routeMsg["uris"].each do |uri|
      puts "from #{uri}"
    end

    open(pathToToml, 'a') {|f|
      f.puts "#{routeMsg["host"]}"
    }
  }

  # rescue SystemExit, Interrupt => e
  #   puts 'Caught SIGINT'
  #   NATS.unsubscribe(sid)
  #   NATS.stop
  #   puts 'Bye'
  # end
end