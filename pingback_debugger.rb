# require File.dirname(__FILE__) + '/vendor/gems/environment'

require "rubygems"
require "bundler"
Bundler.setup

require 'cgi'
require "sinatra"
require "json"
require "sinatra"
require "dm-core"
require "dm-migrations"
require "dm-sqlite-adapter"
require "dm-postgres-adapter"

class Payload
  include DataMapper::Resource
  property :id,      Serial
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
    %{<pre>#{Payload.all(:order => :id.desc).map { |x| CGI.escapeHTML x.payload }.join("\n\n")}</pre>}
  end
  
  post "/" do
    payload = "#{params.inspect}\n#{env['rack.input'].read.inspect}"
    Payload.new(:payload => payload).save
    nil
  end
end
