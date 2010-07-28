# require File.dirname(__FILE__) + '/vendor/gems/environment'

require "rubygems"
require "bundler"
Bundler.setup :default

require "sinatra"
require "json"
require "cgi"
require "dm-core"
require "dm-migrations"
require "dm-sqlite-adapter"
require "dm-postgres-adapter"

class Pingback
  include DataMapper::Resource
  property :id,      Serial
  property :headers, Text
  property :params,  Text
  property :body,    Text
end

configure do
  # Heroku has some valuable information in the environment variables.
  # DATABASE_URL is a complete URL for the Postgres database that Heroku
  # provides for you, something like: postgres://user:password@host/db, which
  # is what DM wants. This is also a convenient check wether we're in production
  # or not.
  db_location = ENV["DATABASE_URL"] || 
                "sqlite3:///#{File.dirname __FILE__}/#{ENV['RACK_ENV']}.sqlite3"
  DataMapper.setup :default, db_location
  DataMapper.auto_upgrade!
end

class PingbackDebugger < Sinatra::Base
  get "/" do
    output = Pingback.all(:order => :id.desc).map do |x|
      CGI.escapeHTML x.body
    end.join("\n\n")
    
    %{<pre>#{output}</pre>}
  end
  
  post "/" do
    Pingback.create \
      :params  => params.to_json,
      :headers => headers.to_json,
      :body    => request.body
    nil
  end
  
  get "/clear" do
    Pingback.all.destroy
    nil
  end
end
