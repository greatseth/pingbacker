ENV['RACK_ENV'] = 'test'

require 'pingback_debugger'
require 'test/unit'

Bundler.setup :test
require 'rack/test'

class PingbackDebuggerTest < Test::Unit::TestCase
  include Rack::Test::Methods
  def app; PingbackDebugger; end
  
  def self.test(description, &block);
    define_method("test #{description}", &block)
  end
  
  def teardown
    Pingback.all.destroy
  end
  
  ###
  
  test "receiving pinbacks" do
    assert_equal 0, Pingback.count
    ping!
    assert last_response.ok?
    assert_equal 1, Pingback.count
  end
  
  test "getting latest pingback" do
    get '/latest.json'
    assert last_response.not_found?
    
    ping!
    assert last_response.ok?
    
    get '/latest.json'
    assert last_response.ok?
    
    pingback = Pingback.first(:order => :id.desc)
    json = nil
    assert_nothing_raised { json = JSON.parse last_response.body }
    assert_equal JSON.parse(pingback.params),  json["params"]
    assert_equal JSON.parse(pingback.headers), json["headers"]
    assert_equal pingback.body, json["body"]
    assert_equal %{"#{pingback.md5}"}, last_response.headers["ETag"]
    
    first_response_etag = last_response.headers["ETag"]
    
    ping! # identical request as the first one
    assert last_response.ok?
    
    get '/latest.json'
    assert last_response.ok?
    
    pingback2 = Pingback.first(:order => :id.desc)
    json = nil
    assert_nothing_raised { json = JSON.parse last_response.body }
    assert_equal JSON.parse(pingback2.params),  json["params"]
    assert_equal JSON.parse(pingback2.headers), json["headers"]
    assert_equal pingback2.body, json["body"]
    assert_equal %{"#{pingback2.md5}"}, last_response.headers["ETag"]
    
    second_response_etag = last_response.headers["ETag"]
    
    assert first_response_etag != second_response_etag
  end
  
  test "clearing pingbacks" do
    assert_equal 0, Pingback.count
    ping!
    assert last_response.ok?
    assert_equal 1, Pingback.count
    get '/clear'
    assert last_response.ok?
    assert_equal 0, Pingback.count
  end
  
  test "listing pingbacks" do
    get '/'
    assert last_response.ok?
  end
  
  ###
  
  def ping!(options = {})
    params   = options[:params]  || {}
    rack_env = options[:headers] || {}
    rack_env["rack.input"] = StringIO.new(
      options[:body] || File.read("encoding-dot-com.xml")
    )
    
    post "/", params, rack_env
  end
end