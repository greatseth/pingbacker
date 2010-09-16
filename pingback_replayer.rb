#!/usr/bin/env ruby
require 'rubygems'
require 'bundler'
Bundler.setup :default, :replayer

require 'active_support'
require 'httparty'
require 'json'
require 'pingback'

class PingbackReplayer
  attr_reader   :pingback
  attr_accessor :target
  
  include HTTParty
  
  def initialize(target)
    self.target = target
  end
  
  def target=(uri)
    @target = uri
    self.class.base_uri target
  end
  
  def replay!(pingback)
    pingback["headers"].each { |k,v| pingback["headers"][k] = v.to_s }
    self.class.post pingback["path"],
      :headers => pingback["headers"], :body => pingback["body"]
  end
end

class PingbackFetcher
  include HTTParty
  base_uri "http://pingback-debugger.heroku.com"
  
  attr_reader :latest_pingback
  attr_reader :latest_pingback_md5
  
  def fetch
    print "fetching latest pingback... "
    response = self.class.get "/pingbacks/next"
    puts "#{response.code} #{response.headers["Etag"]}"
    
    if response.code == 200
      save_pingback(response)
      true
    else
      false
    end
  end
  
private
  def save_pingback(response)
    @latest_pingback_md5   = response.headers["Etag"][1..-2]
    @latest_pingback       = JSON.parse(response.body)
    @received_new_pingback = true
  end
end

if __FILE__ == $0
  fetcher = PingbackFetcher.new
  player  = PingbackReplayer.new "http://localhost:3020"
  
  loop do
    if fetcher.fetch
      puts "fetched pingback #{fetcher.latest_pingback.inspect}", "replaying..."
      response = player.replay! fetcher.latest_pingback 
      puts "result of replay: #{response.inspect}"
    end
    sleep 5
  end
end