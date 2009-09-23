require 'rubygems'
require 'sinatra'
require 'json/pure'
require 'uri'
require 'dm-core'

# patch Net/HTTP interface
require 'appengine-apis/urlfetch'
Net::HTTP = AppEngine::URLFetch::HTTP

# Configure DataMapper to use the App Engine datastore 
DataMapper.setup(:default, "appengine://auto")

class Channel
  include DataMapper::Resource
  property :name, String, :key => true
end

class Subscriber
  include DataMapper::Resource
  property :channel_name, String, :key => true
  property :url, String, :lazy => false
end

helpers do
  def gen_id
    base = rand(100000000)
    salt = Time.now.to_i
    (base + salt).to_s
  end
end

get '/' do
  erb :index
end

post '/channels' do
  id = gen_id
  channel = Channel.create(:name => id)
  { :id => channel.name }.to_json
end

post '/subscribers' do
  res = false
  data = JSON.parse(params[:data])
  channel_name = data['channel'] || 'boo'
  url = data['url'] || nil
  
  if rec = Channel.first(:name => channel_name)
    if url and rec.name
      unless Subscriber.first(:channel_name => rec.name, :url => url)
        res = Subscriber.create(:channel_name => rec.name, :url => url)
      end
    end
  end
  if res
    { :status => 'OK' }.to_json
  else
    { :status => 'FAIL' }.to_json
  end
end

post '/messages' do
  res = false
  data = JSON.parse(params[:data])
  channel_name = data['channel'] || 'boo'
  message = data['message'] || nil
  
  if rec = Channel.first(:name => channel_name)  
    if message and rec.name
      subs = Subscriber.all(:channel_name => rec.name)
      if subs
        subs.each do |sub|
          begin
            url = URI.parse(sub.url)
            conn = Net::HTTP.new(url.host, url.port)
            resp, body = conn.post(url.path, message)
          rescue
          end
          res = true
        end
      end
      
    end
  end
  if res
    { :status => 'OK' }.to_json
  else
    { :status => 'FAIL' }.to_json
  end
end
