#Urlshrink.  A simple URL Shortener meant to be accessed via Ajax, or anything that can speak JSON really.
#By Aashay Desai.  No rights reserved.
$: << "."
require 'rubygems'
require 'sinatra'
require "sinatra/reloader" if development?  #this way we don't have to shut the server down to see changes
require 'dalli'
require 'json'

$cache = Dalli::Client.new('204.236.134.208:11211')  #Dalli is a very nice memcached client

set :public, File.dirname(__FILE__) + '/public/'  #make sure Sinatra knows exactly where our public files are

get '/' do
  send_file(File.join('public', 'index.html')) unless request.xhr?  #TODO: Do something cool if called via XHR?
  #else
  #end
end

get '/:key' do 
  orig = $cache.get(params[:key])
  not_found if orig.nil?
  redirect orig.to_s, 301   #301 redirects tell browsers that this resource has permanently moved.  This is good news for 
                            # pretty much everybody.  All major URLShortners do this, and with good reason!
end

not_found do
    send_file(File.join('public', '404.html'))
end

error do
    JSON.generate({ "errormsg" => env['sinatra.error'].name})
end

post '/' do
  uri = URI::parse(params[:original])
  unless (!uri.nil?) and (uri.kind_of? URI::HTTP or uri.kind_of? URI::HTTPS)
    JSON.generate({ "errormsg" => uri.to_s + " is not a valid URL.  Sorry :("})
  else
    key = getNextKey 
    #key = 'DEV_KEY_ONLY'#TODO - replace with algo
    $cache.set(key, uri)  #store them as actual URI objects so we can mess around with them later if we need to
    JSON.generate({ "shrunk" => key, "original" => uri})
  end
end

# post "/api" do
#     request.body.rewind  # in case someone already read it
#     data = JSON.parse request.body.read
#     "Hello #{data['name']}!"
# end

#create base36 hash
def getNextKey
  globalCounter = $cache.get('GLOBAL_COUNTER')
  
  if globalCounter.nil?
    $cache.set('GLOBAL_COUNTER', 1000000000)
    return 1000000000.to_s(36)
  end
  
  $cache.set('GLOBAL_COUNTER', globalCounter+1) #don't want to deal with incr because apparently that requires string values?
  return (globalCounter+1).to_s(36)
end