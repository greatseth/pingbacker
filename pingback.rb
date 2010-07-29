require "digest/md5"
require "json"
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
  
  def self.setup_db!
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
  
  def self.latest
    first :order => :id.desc
  end
  
  def to_json
    { 
      :headers => parsed(:headers),
      :params  => parsed(:params),
      :body    => body
    }.to_json
  end
  
  def parsed(attribute)
    if attribute_value = send(attribute)
      JSON.parse(attribute_value)
    end
  end
  
# private
  def make_md5
    self.md5 ||= Digest::MD5.hexdigest(
      id.to_s + headers + params + body + "$@17"
    )
  end
end
