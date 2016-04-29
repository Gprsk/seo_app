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
	  @headings = @doc.xpath("//h1")
	  @imgs = @doc.xpath("//img")
	  
  
    #Hash to count words
    h = Hash.new(0)
	  
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
	  	
	  	#Testing length of title
	    if text.length < 55
	    	@results << result.new(tag, text, "Sua tag title possui "+text.length.to_s+" caracteres e está adequada às regras de SEO (abaixo de 60 caracteres)", "Aprovado")
	    elsif text.length > 55 && text.length <= 60
	    	@results << result.new(tag, text, "Sua tag title possui "+text.lenght.to_s+" caracteres, muito próximo ao limite de 60 caracteres.", "Atenção")
	    else
	    	@results << result.new(tag, text, "Sua tag title possui "+text.length.to_s+" caracteres e excedeu o limite de 60 caracteres", "Reprovado")
	    end
	    
	    #Testing for the presence of multiple commas, bars or keyword stuffing
	    # if text.include? ','
	    	
	    # 	case 
	    # 		when text.count(',') == 1
	    # 			@results << result.new(tag, text, "Keyword stuffing", "Atenção")
	    # 		when text.count(',') > 2
	    # 			@results << result.new(tag, text, "Keyword stuffing", "Reprovado")
	    # 		else
	    # 			@results << result.new(tag, text, "Keyword stuffing", "Aprovado")
	    # 	end
	    	
	    # elsif text.include? '|'
	    	
	    # 	case
	    # 		when text.count('|') == 1
	    # 			@results << result.new(tag, text, "Separar o título da página e o título do site com pipe", "Aprovado")
	    # 		when text.count('|') > 2
	    # 			@results << result.new(tag, text, "Excesso de pipes detectado", "Reprovado")
	    # 		else
	    # 			@results << result.new(tag, text, "Sem pipes detecados. Não possui nome no título?", "Atenção")
	    # 	end
	    # end
	    
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
	  
	  #Check if there is a meta description tag
	  if @metas.xpath('//meta[@name="description"]/@content').empty?
	  
	  	@results << result.new(tag, "", "Não foi detectada uma tag META description", "Reprovado")
	
		else
			
		  @metas.xpath('//meta[@name="description"]/@content').each do |meta|
		  	text = meta.text.to_s
		  	
		  	if text.length < 150
		    	@results << result.new(tag, text, "Sua tag meta description possui "+text.length.to_s+" caracteres e está adequada às regras de SEO (abaixo de 160 caracteres)", "Aprovado")
		    elsif text.length > 150 && text.length <= 160
		    	@results << result.new(tag, text, "Sua tag meta description possui "+text.lenght.to_s+" caracteres, muito próximo ao limite de 160 caracteres", "Atenção")
		    else
		    	@results << result.new(tag, text, "Sua tag meta description possui "+text.length.to_s+" caracteres e excedeu o limite de 160 caracteres", "Reprovado")
		    end
		  end
	  end
	  
	  #Check if there's a meta ROBOTS tag
	  if @metas.xpath('//meta[@name="robots"]/@content').empty?
	  	@results << result.new(tag, "", "Não foi detectada uma tag META ROBOTS", "Reprovado")
	  else
	  	@results << result.new(tag, "", "Foi detectada uma tag META ROBOTS", "Aprovado")
	  end
	  
	  #Checking for the headings (h1 tags), if they have some matches to the contents of the title
	  @headings.each do |heading|
	  	text = heading.text.to_s
	  	tag = "<h1>"
	  	
	  	h.each{|key, value|
	  		if heading.text.to_s.downcase.include? key
	  			@results << result.new(tag, text, "As tags heading devem possuir as mesmas palavras-chave do título.", "Aprovado")
	  		else
	  			@results << result.new(tag, text, "As tags heading devem possuir as mesmas palavras-chave do título.", "Reprovado")
	  		end
	  	}
	  	
	  end
	  
	  #Checking for the imgs
	  
	  #Checking for existence of "title" and "alt" attribute
	  totalImg = @imgs.count
	  tag = "<img>"
	  
	  @imgs.each do |img|
	  	
			
	  	text = img.attr('src')
	  	ckAlt = img.attr('alt')
	  	
	  	#binding.pry
	  	
	  	if ckAlt.nil? || ckAlt == ""
	  		@results << result.new(tag, text, "Não foi encontrado o atributo ALT nesta imagem", "Atenção")
	  	else
	  		@results << result.new(tag, text, "Foi encontrado o atributo ALT nesta imagem", "Aprovado")
	  	end
	  	
	  	ckTitle = img.attr('title')
	  	unless ckTitle.nil?
	  		@results << result.new(tag, text, "Foi encontrado o atributo TITLE nesta imagem", "Aprovado")
	  	else
	  		@results << result.new(tag, text, "Não foi encontrado o atributo TITLE nesta imagem", "Reprovado")
	  	end
	  	
	  	#binding.pry
	  end
	  
	  #Outside of any node
	  
	  #Processing console output
	  sum = 0
	  @results.each do |res|
	  	puts res.tag + " | " + res.content + " | " + res.hint + " | " + res.score
	  	
	  	case res.score
	  		when "Aprovado"
	  			sum += 10
	  		when "Atenção"
	  			sum += 4
	  		when "Reprovado"
	  			sum += 1
	  		end
	  		
	  end
	  puts "SCORE FINAL: " + sum.to_s
	  
  end
end
