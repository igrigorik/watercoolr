require 'appengine-rack'

AppEngine::Rack.configure_app(
  :application => 'watercoolr',
  :version => 3
)

require 'watercoolr.rb'
run Sinatra::Application
