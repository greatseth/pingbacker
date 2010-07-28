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
  
  def to_json
    { :headers => headers, :params => params, :body => body }.to_json
  end
  
# private
  def make_md5
    self.md5 ||= Digest::MD5.hexdigest(headers + params + body)
  end
end
