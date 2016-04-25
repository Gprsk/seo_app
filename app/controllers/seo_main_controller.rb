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
	    		when text.count('|') == 1
	    			@results << result.new(tag, text, "Separar o título da página e o título do site com pipe", "Aprovado")
	    		when text.count('|') > 2
	    			@results << result.new(tag, text, "Excesso de pipes detectado", "Reprovado")
	    		else
	    			@results << result.new(tag, text, "Sem pipes detecados. Não possui nome no título?", "Atenção")
	    	end
	    end
	    
	    #Testing with word separation
	    separatedText = text.split(' ')
	    
	    #Hash to count words
	    h = Hash.new(0)
	    
	    separatedText.each_with_index do |sT, index|
	    	
	    	#Counting words
	    	unless sT.length < 2
	    		h[sT] +=1
	    	end
	    	
	    	#string.include? => true/false
	    	
	    	#if sT.include? @domain
	    	#	@results << result.new(tag, text, "Nome do site deve ser similar ao domínio, ao final do título.", "Reprovado")
	    	#end
	    	
	    	
	    end
	    
	    #Processing the countage of words
	    h.each {|key, value| 
	    	if value > 3
	    		@results << result.new(tag, text, "Há repetição exagerada da palavra #key", "Reprovado")
	    	end
	    }
	    #puts @results.map{|result| result.score}
	  end
	  
	 
	  #Loop - metatag name=description check
	  
	  tag = "<meta>"
	  
	  @metas.xpath('//meta[@name="description"]/@content').each do |meta|
	  	text = meta.text.to_s
	  	
	  	if text.length < 150
	    	@results << result.new(tag, text, "Descrição não deve exceder 160 caracteres", "Aprovado")
	    elsif text.length > 150 && text.length <= 160
	    	@results << result.new(tag, text, "Descrição não deve exceder 160 caracteres", "Atenção")
	    else
	    	@results << result.new(tag, text, "Descrição não deve exceder 160 caracteres", "Reprovado")
	    end
	  	
	  end

  end
end
