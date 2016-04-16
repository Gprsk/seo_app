#http://ruby-doc.org/core-2.1.2/String.html#method-i-length

class SeoMainController < ApplicationController
  def index
  end

  def show
  	@url = params[:url]

  	require 'open-uri'
  	require 'net/https'
  	require 'openssl'
  	
  	#-----
  	#Getting domain
  	#Addressable::URI.parse("http://techcrunch.com/foo/bar").host #=> "techcrunch.com"
  	#-----
  	
  	#@url = 'http://' + @url unless @url.match(/^http:\/\//)
  	#@domain = Addressable::URI.parse(@url).host
  	
  	#----
  	#Mounting main documents and reading tags
  	#----
  	
	  @doc = Nokogiri::HTML(open(@url, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
	  @titles = @doc.xpath("//title")
	  @metas = @doc.xpath("//meta")
	  
	  #----
	  #Converting the whole document to string
	  #----
	  unless @doc.to_s.valid_encoding?
	  	@doc.to_s.force_encoding("utf-8")
	  end
	  
	  
	  #Array with results of the tests
	  #Should be shown as the final result
	  #@results has an array of the struct result, each result is an individual line
	  @results = []
	  result = Struct.new(:tag, :content, :hint, :score)
	  
	  
	  #Loop - title check
	  @titles.each do |title|
	  	text = title.text.to_s
	  	tag = "<title>"
	  	hint = "Títulos acima de 60 caracteres não são exibidos corretamente pelo Google."
	  	
	  	#Testing length of title
	    if text.length < 55
	    	@results << result.new(tag, text, hint, "Aprovado")
	    elsif text.length > 55 && text.length <= 60
	    	@results << result.new(tag, text, hint, "Atenção")
	    else
	    	@results << result.new(tag, text, hint, "Reprovado")
	    end
	    
	    #Testing for the presence of multiple commas, bars or keyword stuffing
	    if text.include? ','
	    	
	    	case 
	    		when text.count(',') == 1
	    			@results << result.new(tag, text, "Keyword stuffing", "Atenção")
	    		when text.count(',') > 2
	    			@results << result.new(tag, text, "Keyword stuffing", "Reprovado")
	    		else
	    			@results << result.new(tag, text, "Keyword stuffing", "Aprovado")
	    	end
	    	
	    elsif text.include? '|'
	    	
	    	case
	    		when text.count('|')
	    		else
	    	end
	    end
	    
	    #Testing domain presence
	    separatedText = text.split(' ')
	    separatedText.each_with_index do |sT, index|
	    	#string.include? => true/false
	    	
	    	#if sT.include? @domain
	    	#	@results << result.new(tag, text, "Nome do site deve ser similar ao domínio, ao final do título.", "Reprovado")
	    	#end
	    	
	    end
	    
	    #puts @results.map{|result| result.score}
	  end
	  
	 
	  #Loop - metatags check
	  @metas.each do |meta|
	    #puts meta
	  end

  end
end
