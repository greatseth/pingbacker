# require File.dirname(__FILE__) + '/vendor/gems/environment'
Bundler.setup

require "rubygems"
require "sinatra"
require "json"
require "sinatra"
require "dm-core"

class Payload
  include DataMapper::Resource
  property :id,      Integer, :serial => true
  property :payload, Text
end

configure do
  # Heroku has some valuable information in the environment variables.
  # DATABASE_URL is a complete URL for the Postgres database that Heroku
  # provides for you, something like: postgres://user:password@host/db, which
  # is what DM wants. This is also a convenient check wether we're in production
  # / not.
  DataMapper.setup(:default,
    (ENV["DATABASE_URL"] || "sqlite3:///#{File.dirname __FILE__}/development.sqlite3"))
  DataMapper.auto_upgrade!
end

class PayloadPrinter < Sinatra::Base
  get "/" do
    %{<pre>#{Payload.all(:order => :id.desc).map { |x| x.payload }.join("\n\n")}</pre>}
  end
  
  post "/" do
    payload = "#{params.inspect}\n#{env['rack.input']}"
    Payload.new(:payload => payload).save
    nil
  end
end
