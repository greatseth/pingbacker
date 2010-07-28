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
    post '/'
    assert last_response.ok?
    assert_equal 1, Pingback.count
  end
  
  test "listing pingbacks" do
    get '/'
    assert last_response.ok?
  end
  
  test "clearing pingbacks" do
    assert_equal 0, Pingback.count
    post '/'
    assert last_response.ok?
    assert_equal 1, Pingback.count
    get '/clear'
    assert last_response.ok?
    assert_equal 0, Pingback.count
  end
end