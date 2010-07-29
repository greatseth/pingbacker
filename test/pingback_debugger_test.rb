require 'test_helper'
require 'rack/test'

require 'pingback_debugger'

class PingbackDebuggerTest < Test::Unit::TestCase
  include Rack::Test::Methods
  def app; PingbackDebugger; end
  
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
    
    pingback = Pingback.latest
    assert_not_nil pingback
    
    get '/latest.json'
    assert last_response.ok?
    
    json = nil
    assert_nothing_raised { json = JSON.parse last_response.body }
    assert_equal pingback.parsed(:params),  json["params"]
    assert_equal pingback.parsed(:headers), json["headers"]
    assert_equal pingback.body, json["body"]
    assert_equal %{"#{pingback.md5}"}, last_response.headers["ETag"]
    
    get '/latest.json'
    assert last_response.not_found?
    
    ping!
    assert last_response.ok?
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