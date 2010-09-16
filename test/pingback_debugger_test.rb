require 'test_helper'
require 'rack/test'

require 'bson'
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
  
  test "getting next pingback" do
    next!
    assert last_response.not_found?
    
    ping!
    assert last_response.ok?
    
    pingback = Pingback.next
    assert_not_nil pingback
    assert_not_nil pingback.parsed(:params)
    default_request_headers.each do |k,v|
      assert_equal v, pingback.parsed(:headers)[k]
    end
    assert_equal default_pingback_body, pingback.body
    assert_equal last_pingback_path, pingback.path
    
    next!
    assert last_response.ok?
    
    json = nil
    assert_nothing_raised { json = JSON.parse last_response.body }
    assert_equal pingback.parsed(:params),  json["params"]
    # assert pingback.parsed(:params)["job_id"]
    assert_equal pingback.parsed(:headers)["Content-Type"], json["headers"]["Content-Type"]
    assert_equal pingback.body, json["body"]
    assert_equal pingback.path, json["path"]
    assert_equal %{"#{pingback.md5}"}, last_response.headers["ETag"]
    
    next!
    assert last_response.not_found?
    
    ping!
    assert last_response.ok?
  end
  
  test "clearing pingbacks" do
    assert_equal 0, Pingback.count
    ping!
    assert last_response.ok?
    assert_equal 1, Pingback.count
    delete '/pingbacks'
    assert last_response.ok?
    assert_equal 0, Pingback.count
  end
  
  test "listing pingbacks" do
    get '/pingbacks'
    assert last_response.ok?
  end
  
  ###
  
  def ping!(options = {})
    params   = options[:params]  || {}
    rack_env = default_request_headers.merge(options[:headers] || {})
    
    # without this, Rack parses the body into params.. 
    # seems like a bug, but haven't probed Rack enought to know for sure
    rack_env["CONTENT_TYPE"] = rack_env["Content-Type"]
    
    rack_env["rack.input"] = StringIO.new(
      options[:body] || default_pingback_body
    )
    
    @last_pingback_path = default_pingback_path
    pingbacks_before = Pingback.count
    response = post last_pingback_path, params, rack_env
    pingbacks_after  = Pingback.count
    assert pingbacks_after == (pingbacks_before + 1), "failed to add pingback"
    response
  end
  
  def next!
    get '/pingbacks/next'
  end
  
  def default_pingback_body
    File.read("encoding-dot-com.xml")
  end
  
  def default_request_headers
    { "Content-Type" => "application/xml" }
  end
  
  def default_pingback_path
    "/jobs/#{BSON::ObjectId.new}/pingback"
  end
  
  attr_reader :last_pingback_path
end