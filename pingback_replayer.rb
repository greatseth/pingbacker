#!/usr/bin/env ruby

#############################################################################
#                                                                           #
# If you want to use this file, see the "if __FILE__ == $0" section         #
# at the end of the file for example usage. In the future this file may be  #
# made able to be run in a customizable fashion. Patches welcome! :P        #
#                                                                           #
#############################################################################

require 'rubygems'
require 'bundler'
Bundler.setup :default, :replayer

require 'active_support'
require 'httparty'
require 'json'
require 'pingback'
require 'cgi'

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
  base_uri ENV['PINGBACKER_BASE_URI']
  
  attr_reader :latest_pingback
  attr_reader :silo
  
  def initialize(silo)
    silo = silo.to_s
    raise ArgumentError, "invalid silo: #{silo.inspect}" if silo.empty?
    @silo = silo
  end
  
  def fetch
    path = "/silos/#{CGI.escape silo}/pingbacks/next"
    
    print "fetching latest pingback... looking in #{self.class.base_uri}#{path}... "
    
    # TODO extract URL generation from tests for reuse
    response = self.class.get path
    
    puts "#{response.code} #{response.headers["Etag"]}"
    
    if response.code == 200
      save_pingback(response)
      begin
        system "growlnotify -m 'Pingback received: #{response.inspect.gsub "'", "\\'"}'"
      rescue StandardError => e
        puts e
      end
      true
    else
      false
    end
  end
  
private
  def save_pingback(response)
    @latest_pingback = JSON.parse(response.body)
  end
end

if __FILE__ == $0
  fetcher = PingbackFetcher.new  ENV['PINGBACKER_SILO']
  player  = PingbackReplayer.new ENV['PINGBACK_REPLAYER_HOST']
  
  loop do
    if fetcher.fetch
      puts "fetched pingback #{fetcher.latest_pingback.inspect}", "replaying..."
      response = player.replay! fetcher.latest_pingback 
      puts "result of replay: #{response.inspect}"
    end
    sleep 5
  end
end