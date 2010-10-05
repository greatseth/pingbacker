require 'test_helper'
require 'pingback'
Pingback.setup_db!

class PingbackTest < Test::Unit::TestCase
  def teardown
    Pingback.all.destroy
  end
  
  test "parsed accessors" do
    pingback = Pingback.new
    assert_equal Hash.new, pingback.parsed(:params)
    assert_equal Hash.new, pingback.parsed(:headers)
    
    stuff = { "foo" => "bar" }
    
    pingback.params  = stuff.to_json
    pingback.headers = stuff.to_json
    
    assert_equal stuff, pingback.parsed(:params)
    assert_equal stuff, pingback.parsed(:headers)
  end
  
  test "next in a silo" do
    assert_nil Pingback.in_silo('test').next
    
    pingback1 = Pingback.in_silo('test').create!
    assert_equal pingback1.id, Pingback.in_silo('test').next.id
    
    pingback2 = Pingback.in_silo('test').create!
    assert_equal pingback1.id, Pingback.in_silo('test').next.id
    
    pingback1.destroy
    
    assert_equal pingback2.id, Pingback.in_silo('test').next.id
  end
end
