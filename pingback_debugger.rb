require "rubygems"
require "bundler"
Bundler.setup :default

require "sinatra"
require "digest/md5"
require "json"
require "cgi"
require "dm-core"
require "dm-validations"
require "dm-migrations"
require "dm-sqlite-adapter"
require "dm-postgres-adapter"

class Pingback
  include DataMapper::Resource
  
  property :id,      Serial
  property :headers, Text
  property :params,  Text
  property :body,    Text
  property :md5,     Text
  
  validates_presence_of :headers, :params, :body, :md5
  
  # before :valid?, :make_md5
  
  def to_json
    { :headers => headers, :params => params, :body => body }.to_json
  end
  
# private
  def make_md5
    self.md5 ||= Digest::MD5.hexdigest(headers + params + body)
  end
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
  get "/latest.json" do
    @pingback = Pingback.first(:order => :id.desc)
    
    if @pingback
      content_type "application/json"
      etag @pingback.md5
      @pingback.to_json
    else
      404
    end
  end
  
  post "/" do
    @pingback = Pingback.new \
      :params  => params.to_json,
      :headers => headers.to_json,
      :body    => request.body.read
    
    # TODO figure out how to use dm-validations and callbacks :\
    @pingback.make_md5
    
    if @pingback.save
      200
    else
      error 500, @pingback.errors.inspect
    end
  end
  
  get "/clear" do
    Pingback.all.destroy
    nil
  end
end
