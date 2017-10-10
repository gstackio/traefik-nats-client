#!/usr/bin/env ruby
require 'nats/client'
require 'rubygems'
require 'json'
require 'net/http'

sid = 0

NATS.start(:servers => [ 'nats://nats:nats@10.244.0.6:4222', 'nats://nats:nats@10.244.2.6:4222' ]) do

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

    httpResp = Net::HTTP.get_response(URI.parse('http://traefik.ecf.prototyp.it:18080/api/providers/web'))
    traefikWeb = JSON.parse(httpResp.body)
    puts traefikWeb

    #backend block

  }

  # rescue SystemExit, Interrupt => e
  #   puts 'Caught SIGINT'
  #   NATS.unsubscribe(sid)
  #   NATS.stop
  #   puts 'Bye'
  # end
end

