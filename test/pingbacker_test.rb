require 'test_helper'
require 'rack/test'

require 'bson'
require 'pingbacker'

class PingbackerTest < Test::Unit::TestCase
  DEFAULT_SILO = 'test'
  
  include Rack::Test::Methods
  def app; Pingbacker; end
  
  attr_reader :last_pingback_path
  attr_reader :last_pingback_actual_path
  
  def teardown
    Pingback.all.destroy
  end
  
  ###
  
  test "receiving pinbacks" do
    assert_equal 0, Pingback.count
    assert_equal 0, Pingback.in_silo(DEFAULT_SILO).count
    assert_equal 0, Pingback.in_silo('other').count
    ping!
    assert last_response.ok?
    assert_equal 1, Pingback.count
    assert_equal 1, Pingback.in_silo(DEFAULT_SILO).count
    assert_equal 0, Pingback.in_silo('other').count
  end
  
  test "getting next pingback" do
    next!
    assert last_response.not_found?
    
    ping!
    assert last_response.ok?
    
    pingback = Pingback.in_silo(DEFAULT_SILO).next
    assert_not_nil pingback
    assert_not_nil pingback.parsed(:params)
    default_request_headers.each do |k,v|
      assert_equal v, pingback.parsed(:headers)[k]
    end
    assert_equal default_pingback_body, pingback.body
    assert_equal last_pingback_actual_path, pingback.path
    
    next! 'other'
    assert last_response.not_found?
    
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
    assert_equal 0, Pingback.in_silo(DEFAULT_SILO).count
    ping!
    assert last_response.ok?
    assert_equal 1, Pingback.count
    assert_equal 1, Pingback.in_silo(DEFAULT_SILO).count
    delete silo_path(DEFAULT_SILO, "/pingbacks")
    assert last_response.ok?
    assert_equal 0, Pingback.count
    assert_equal 0, Pingback.in_silo(DEFAULT_SILO).count
  end
  
  test "listing pingbacks" do
    get silo_path(DEFAULT_SILO, "/pingbacks")
    assert last_response.ok?
  end
  
  ###
  
  def ping!(options = {})
    params   = options[:params]  || {}
    rack_env = default_request_headers.merge(
      options[:headers] || {}
    )
    
    # without this, Rack parses the body into params.. 
    # seems like a bug, but haven't probed Rack enought to know for sure
    rack_env["CONTENT_TYPE"] = rack_env["Content-Type"]
    
    rack_env["rack.input"] = StringIO.new(
      options[:body] || default_pingback_body
    )
    
    @last_pingback_path = options[:path] || default_pingback_path
    @last_pingback_actual_path = last_pingback_path[/^#{silo_path_base}(.+)$/, 1]
    pingbacks_before = Pingback.count
    response = post last_pingback_path, params, rack_env
    pingbacks_after  = Pingback.count
    assert pingbacks_after == (pingbacks_before + 1), "failed to add pingback"
    response
  end
  
  def next!(silo = DEFAULT_SILO)
    get silo_path(silo, "/pingbacks/next")
  end
  
  def default_pingback_body
    File.read("encoding-dot-com.xml")
  end
  
  def default_request_headers
    { "Content-Type" => "application/xml" }
  end
  
  def default_pingback_path(silo = DEFAULT_SILO)
    silo_path(silo, default_pingback_actual_path)
  end
  
  def default_pingback_actual_path
    "/jobs/#{BSON::ObjectId.new}/pingback"
  end
  
  def silo_path(silo, path = "/")
    "#{silo_path_base silo}#{path}"
  end
  
  def silo_path_base(silo = DEFAULT_SILO)
    "/silos/#{CGI.escape silo}"
  end
end