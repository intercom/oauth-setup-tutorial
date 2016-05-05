#!/usr/bin/env ruby
#
# This code snippet shows how to enable SSL in Sinatra+Thin.
#

require 'sinatra'
require 'thin'
require 'json'
require 'slim'
require 'json'
require "net/http"
require "uri"
require 'intercom'

class MyThinBackend < ::Thin::Backends::TcpServer
  def initialize(host, port, options)
    super(host, port)
    @ssl = true
    @ssl_options = options
  end
end

configure do
  set :environment, :production
  set :bind, '0.0.0.0'
  #:set :port, 443
  set :server, "thin"
  enable :sessions
  class << settings
    def server_settings
      {
          :backend          => MyThinBackend,
          :private_key_file => File.dirname(__FILE__) + "/pkey.pem",
          :cert_chain_file  => File.dirname(__FILE__) + "/cert.crt",
          :verify_peer      => false
      }
    end
  end
end

get '/' do
  File.read('intercom.html')
end

get '/home' do
  "Welcome Back"
end

get '/callback' do
  #Get the Code passed back to our redirect callback
  session[:code] = params[:code]
  session[:state] = params[:state]

  puts "CODE: #{session[:code]}"
  puts "STATE:#{session[:state]}"

  #We can do a Post now to get the access token
  uri = URI.parse("https://api.intercom.io/auth/eagle/token")
  response = Net::HTTP.post_form(uri, {"code" => params[:code],
                                       "client_id" => "212a4d34-f160-42b5-8010-83af85f91b0f",
                                       "client_secret" => "054d68dd-fa51-4347-a522-980e87c1fb3f"})

  #Break Up the response and print out the Access Token
  rsp = JSON.parse(response.body)
  session[:token] = rsp["token"]

  puts "ACCESS TOKEN: #{session[:token]}"
  redirect '/home'
end

#post '/callback' do
#  push = JSON.parse(request.body.read)
#  puts "I got some JSON: #{push.inspect}"
#end