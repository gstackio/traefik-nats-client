#!/usr/bin/env ruby
require 'nats/client'
require 'rubygems'
require 'json'
require 'http'

def test_code
  providers_json = HTTP.headers(:accept => 'application/json')
    .get('http://traefik.ecf.prototyp.it:18080/api/providers/web').to_s

  puts "#{providers_json}\n"

  providers = JSON.parse(providers_json)

  providers['backends']['back-cf-production']['servers']['server2'] = {
      'url' => 'localhost:8080',
      'weight' => 0
  }


  HTTP.headers(:accept => 'application/json')
    .put('http://traefik.ecf.prototyp.it:18080/api/providers/web', :json => providers)


  providers_json = HTTP.headers(:accept => 'application/json')
    .get('http://traefik.ecf.prototyp.it:18080/api/providers/web').to_s

  puts "#{providers_json}\n"
end

# test_code
# exit



def updateFrontendConfiguration(currentConfiguration, routeUpdate)
  uris = routeUpdate['uris']
  frontendConfigurations = currentConfiguration['frontends']
  uris.each do |uri|
    frontendConfigurations[uri + '-fe'] = {'routes' => {'route1' => {'rule' => 'Host: ' + uri }},
                                               'passHostHeader' => true,
                                               'entryPoints' => ['http', 'https'],
                                               'backend' => uri + '-be'}
  end
end

def updateBackendConfiguration(currentConfiguration, routeUpdate)
  uris = routeUpdate['uris']
  backendConfigurations = currentConfiguration['backends']
  uris.each do |uri|
    backendConfigurations[uri + '-be'] = {'servers' => {'server1' => {'url' => "http://#{routeUpdate['host']}:#{routeUpdate['port']}" }}}
  end
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

    providers_json = HTTP.headers(:accept => 'application/json')
      .get('http://traefik.ecf.prototyp.it:18080/api/providers/web');

    if providers_json.code == 200
      traefikWeb = JSON.parse(providers_json.to_s)
    else
      traefikWeb = {'frontends' => {}, 'backends' => {}}
    end

    puts traefikWeb
    puts "\n"

    updateFrontendConfiguration(traefikWeb, routeMsg)
    updateBackendConfiguration(traefikWeb, routeMsg)

    puts traefikWeb
    puts "\n"

    HTTP.headers(:accept => 'application/json')
    .put('http://traefik.ecf.prototyp.it:18080/api/providers/web', :json => traefikWeb)

    #backend block
  }

end

