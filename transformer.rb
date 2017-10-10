#!/usr/bin/env ruby
require 'nats/client'
require 'rubygems'
require 'json'
require 'net/http'
require 'rest_client'

sid = 0
http = Net::HTTP.new('http://traefik.ecf.prototyp.it', 18080)

def updateFrontend(currentConfiguration, routeUpdate)
  uris = routeUpdate['uris']
  frontendConfigurations = currentConfiguration['frontends']
  frontendConfigurations.each do |key, value|
    if key == uris[0] + '-fe'
      puts frontendConfigurations[key]['routes']
      #frontendConfigurations[key]['routes']['route1']['rule'] = 'Host: ' + uris[0]
    end
  end
  puts 'Frontend DONE'
end


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
    puts "dest IP: '#{routeMsg['host']}'"
    puts "dest Port: '#{routeMsg['port']}'"
    routeMsg['uris'].each do |uri|
      puts "from #{uri}"
    end

    httpResp = http.request_get('/api/providers/web')
    traefikWeb = JSON.parse(httpResp.body)
    puts traefikWeb

    updateFrontend(traefikWeb, routeMsg)

    newServer         = {}
    newServer[:url]  = 'localhost:8080'
    newServer[:weight] = 0
    traefikWeb['backends']['back-cf-production']['servers']['server2'] = newServer

    #http.request_put('/api/providers/web', JSON.generate(newServer))


    #backend block
  }

end

