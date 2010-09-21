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
  get "/" do
    redirect "/pingbacks"
  end
  
  get "/pingbacks" do
    output = Pingback.all(:order => :id.desc).map do |x|
      CGI.escapeHTML x.body
    end.join("\n\n")
    
    %{<pre>#{output}</pre>}
  end
  
  get "/pingbacks/next" do
    @pingback = Pingback.next
    
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
    
  post "*" do
    @pingback = Pingback.new \
      :params  => params.to_json,
      :headers => request.env.to_json,
      :body    => request.body.read,
      :path    => request.path
    
    # TODO figure out how to use dm-validations and callbacks :\
    @pingback.make_md5
    
    if @pingback.save
      200
    else
      error 500, @pingback.errors.inspect
    end
  end
  
  delete "/pingbacks" do
    Pingback.all.destroy
    200
  end
end