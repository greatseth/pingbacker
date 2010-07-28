ENV['RACK_ENV'] = 'test'

require 'pingback_debugger'
require 'test/unit'

Bundler.setup :test
require 'rack/test'

class PingbackDebuggerTest < Test::Unit::TestCase
  include Rack::Test::Methods
  def app; PingbackDebugger; end
  
  def self.test(description, &block)
    define_method("test #{description}", &block)
  end
  
  def teardown
    Pingback.all.destroy
  end
  
  test "receiving pinbacks" do
    assert_equal 0, Pingback.count
    create_pingback
    assert last_response.ok?
    assert_equal 1, Pingback.count
  end
  
  test "getting latest pingback" do
    get '/latest.json'
    assert last_response.not_found?
    create_pingback
    assert last_response.ok?
    get '/latest.json'
    assert last_response.ok?
    assert_nothing_raised { JSON.parse last_response.body }
    assert_equal '"' + Pingback.first(:order => :id.desc).md5 + '"',
                 last_response.headers["ETag"]
  end
  
  test "clearing pingbacks" do
    assert_equal 0, Pingback.count
    create_pingback
    assert last_response.ok?
    assert_equal 1, Pingback.count
    get '/clear'
    assert last_response.ok?
    assert_equal 0, Pingback.count
  end
  
  def create_pingback(options = {})
    params   = options[:params]  || {}
    rack_env = options[:headers] || {}
    rack_env["rack.input"] = StringIO.new(options[:body] || "test")
    
    post "/", params, rack_env
  end
end