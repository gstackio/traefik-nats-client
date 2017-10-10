#!/usr/bin/env ruby
require 'nats/client'
require 'rubygems'
require 'json'
require 'http'
require 'rest_client'


def test_code
  providers_json = HTTP.headers(:accept => "application/json")
    .get("http://traefik.ecf.prototyp.it:18080/api/providers/web").to_s
  
  puts "#{providers_json}\n"
  
  providers = JSON.parse(providers_json)
  
  providers["backends"]["back-cf-production"]["servers"]["server2"] = {
    "url" => 'localhost:8080',
    "weight" => 0
  }


  HTTP.headers(:accept => "application/json")
    .put("http://traefik.ecf.prototyp.it:18080/api/providers/web", :json => providers)


  providers_json = HTTP.headers(:accept => "application/json")
    .get("http://traefik.ecf.prototyp.it:18080/api/providers/web").to_s

  puts "#{providers_json}\n"
end

# test_code
# exit



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
    puts "\n"

    providers_json = HTTP.headers(:accept => "application/json")
      .get("http://traefik.ecf.prototyp.it:18080/api/providers/web").to_s

    traefikWeb = JSON.parse(providers_json)
    puts traefikWeb
    puts "\n"

    updateFrontend(traefikWeb, routeMsg)

    traefikWeb["backends"]["back-cf-production"]["servers"]["server2"] = {
      "url" => 'localhost:8080',
      "weight" => 0
    }

    HTTP.headers(:accept => "application/json")
      .put("http://traefik.ecf.prototyp.it:18080/api/providers/web", :json => traefikWeb)

    #backend block
  }

end

