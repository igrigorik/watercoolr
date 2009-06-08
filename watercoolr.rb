require 'rubygems'
require 'sinatra'
require 'sequel'
require 'rest_client'
require 'zlib'
require 'json'

configure do
  DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://watercoolr.db')
  unless DB.table_exists? "channels"
    DB.create_table :channels do
      primary_key :id
      varchar :name, :size => 256
    end
  end

  unless DB.table_exists? "subscribers"
    DB.create_table :subscribers do
      primary_key :id
      integer :channel_id, :size => 11
      varchar :url, :size => 256
    end
  end
end

helpers do
  def gen_id
    base = rand(100000000).to_s
    salt = Time.now.to_s
    Zlib.crc32(base + salt).to_s(36)
  end
end



get '/' do
  erb :index
end

post '/channels' do
  id = gen_id
  DB[:channels] << { :name => id }
  { :id => id.to_s }.to_json
end

post '/subscribers' do
  res = false
  data = JSON.parse(params[:data])
  channel_name = data['channel'] || 'boo'
  url = data['url'] || nil
  if rec = DB[:channels].filter(:name => channel_name).first
    if url and rec[:id]
      res = DB[:subscribers] << { :channel_id => rec[:id], :url => url }
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
  if rec = DB[:channels].filter(:name => channel_name).first
    if message and rec[:id]
      subs = DB[:subscribers].filter(:channel_id => rec[:id]).to_a
      if subs
        subs.each do |sub|
          begin
            RestClient.post sub[:url], :data => message 
            puts url
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

