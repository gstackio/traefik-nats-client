#!/usr/bin/env ruby
require 'nats/client'
require 'rubygems'
require 'json'
require 'net/http'

sid = 0
traefikUrl = URI.parse('http://traefik.ecf.prototyp.it:18080/api/providers/web')

if ARGV.length>0
  natsEndpoints = ARGV[0].split(',')
else
  natsEndpoints = [ 'nats://localhost:4222']
end


NATS.start(:servers => natsEndpoints) do

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

    httpResp = Net::HTTP.get_response(traefikUrl)
    traefikWeb = JSON.parse(httpResp.body)
    puts traefikWeb

    # Net::HTTP.put2(traefikUrl, httpResp.body)

    #backend block

  }

  # rescue SystemExit, Interrupt => e
  #   puts 'Caught SIGINT'
  #   NATS.unsubscribe(sid)
  #   NATS.stop
  #   puts 'Bye'
  # end
end

