require "rubygems"
require "bundler"
Bundler.setup :default

require "sinatra"
require "cgi"
require "pingback"

configure do
  Pingback.setup_db!
end

class Pingbacker < Sinatra::Base
  get "/silos/:silo/pingbacks" do
    output = Pingback.in_silo(params[:silo]).all(:order => :id.desc).map do |x|
      CGI.escapeHTML x.body
    end.join("\n\n")
    
    %{<pre>#{output}</pre>}
  end
  
  get "/silos/:silo/pingbacks/next" do
    @pingback = Pingback.in_silo(params[:silo]).next
    
    if @pingback
      content_type "application/json"
      etag @pingback.md5
      json = @pingback.to_json
      @pingback.destroy
      json
    else
      404
    end
  end
    
  post "/silos/:silo/*" do
    @pingback = Pingback.new \
      :params  => params.to_json,
      :headers => request.env.to_json,
      :body    => request.body.read,
      :path    => "/" + params[:splat].join("/"),
      :silo    => params[:silo]
    
    # TODO figure out how to use dm-validations and callbacks :\
    @pingback.make_md5
    
    if @pingback.save
      200
    else
      error 500, @pingback.errors.inspect
    end
  end
  
  delete "/silos/:silo/pingbacks" do
    Pingback.in_silo(params[:silo]).destroy
    200
  end
end
