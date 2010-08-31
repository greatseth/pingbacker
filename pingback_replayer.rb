#!/usr/bin/env ruby
require 'rubygems'
require 'bundler'
Bundler.setup

require 'net/http'
require 'json'
require 'pingback'

class PingbackReplayer
  module HTTPHelper
    def make_request(net_http_method_class_name, path, options = {})
      url = URI.parse "http://pingback-debugger.heroku.com"
      request  = Net::HTTP.const_get(net_http_method_class_name).new(path)
      response = Net::HTTP.start(url.host, url.port) { |h| h.request(request) }
    end
  end
  include HTTPHelper
  
  attr_reader   :pingback
  attr_accessor :target
  
  def initialize(target)
    self.target = target
  end
  
  def target=(url)
    @target = URI.parse url
  end
  
  def replay!(pingback)
    path    = target.path == "" ? "/" : target.path
    request = Net::HTTP::Post.new(path)
    
    pingback["headers"].each { |k,v| request[k] = v }
    
    request.body = pingback["body"]
    
    request.set_form_data pingback["params"]
    
    Net::HTTP.start(target.host, target.port) { |h| h.request(request) }
  end
end

class PingbackFetcher
  attr_reader :latest_pingback
  attr_reader :latest_pingback_md5
  
  def fetch
    print "fetching latest pingback..."
    
    url      = URI.parse "http://pingback-debugger.heroku.com"
    request  = Net::HTTP::Get.new("/next.json")
    
    response = Net::HTTP.start(url.host, url.port) { |h| h.request(request) }
    puts response.code
    puts "ETag: #{response["Etag"]}"
    
    # if pingback_stored?
    #   if new_pingback?(response)
    #     save_pingback(response)
    #   else
    #     @received_new_pingback = false
    #   end
    # else
    #   save_pingback(response)
    # end
    
    puts latest_pingback.inspect
    
    if response.code == 200
      save_pingback(response)
      true
    else
      false
    end
  end
  
  # def received_new_pingback?
  #   @received_new_pingback
  # end
  
private
  # def pingback_stored?
  #   not latest_pingback.nil? and not latest_pingback_md5.nil?
  # end
  # 
  # def new_pingback?(response)
  #   latest_pingback_md5 != response["Etag"][1..-2]
  # end
  
  def save_pingback(response)
    @latest_pingback_md5   = response["Etag"][1..-2]
    @latest_pingback       = JSON.parse(response.body)
    @received_new_pingback = true
  end
end

if __FILE__ == $0
  fetcher = PingbackFetcher.new
  player  = PingbackReplayer.new "http://localhost:9292"
  
  loop do
    puts "fetching latest pingback"
    if fetcher.fetch
      puts "fetched pingback: #{fetcher.latest_pingback.inspect}",
           "replaying.."
      response = player.replay! fetcher.latest_pingback 
      puts "result of replay: #{response.inspect}"
    end
    sleep 20
  end
end