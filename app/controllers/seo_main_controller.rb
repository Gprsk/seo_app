#http://ruby-doc.org/core-2.1.2/String.html#method-i-length

class SeoMainController < ApplicationController
  def index
  end

  def show
  	@url = params[:url]

  	require 'open-uri'
	  @doc = Nokogiri::HTML(open(@url))
	  @titles = @doc.xpath("//title")
	  @metas = @doc.xpath("//meta")
	  
	  #Array with results of the tests
	  @results = []
	  
	  unless @doc.to_s.valid_encoding?
	  	@doc.to_s.force_encoding("utf-8")
	  end

	  result = Struct.new(:tag, :content, :score)
	  #Loop - title check
	  @titles.each do |title|
	  	text = title.text.to_s
	    #Remove namespaces and tags?
	    #title.replace(title.text) #->not working
	    #title.replace(Nokogiri::XML::Text.new(title.inner_html, title.document)) # ->not working
	    
	    #Length
	    if text.length < 56
	    	@results << result.new("title", "cefsa", "0")
	    else
	    	@results << result.new("title", "cefsa", "10")
	    end
	    puts @results.map{|result| result.score}
	  end
	  
	 
	  #Loop - metatags check
	  @metas.each do |meta|
	    #puts meta
	  end

  end
end
