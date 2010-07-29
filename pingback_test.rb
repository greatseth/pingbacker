require 'test_helper'
require 'pingback'
Pingback.setup_db!

class PingbackTest < Test::Unit::TestCase
  test "latest" do
    assert_nil Pingback.latest
    
    pingback1 = Pingback.create!
    assert_equal pingback1.id, Pingback.latest.id
    
    pingback2 = Pingback.create!
    assert_equal pingback2.id, Pingback.latest.id
  end
end
