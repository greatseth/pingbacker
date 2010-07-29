ENV['RACK_ENV'] = 'test'
require 'rubygems'
require 'bundler'
Bundler.setup :test

require 'test/unit'

class Test::Unit::TestCase
  def self.test(description, &block);
    define_method("test #{description}", &block)
  end
end
