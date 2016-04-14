class SeoMainController < ApplicationController
  def index
  end

  def show
  	@url = params[:url]

  	require 'open-uri'
	  @doc = Nokogiri::HTML(open(@url))
	  
	  @titles = @doc.xpath("//title")
	  @metas = @doc.xpath("//meta")
	  
	  #Loop - title check
	  @titles.each do |title|
	    #Remove namespaces and tags?
	    #title.replace(title.text) #->not working
	    #title.replace(Nokogiri::XML::Text.new(title.inner_html, title.document)) # ->not working
	    puts title.to_s
	  end
	  
	  #Loop - metatags check
	  @metas.each do |meta|
	    #puts meta
	  end

  end
end
