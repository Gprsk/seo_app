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
	  @titles = @doc.xpath("//head/title")
	  @metas = @doc.xpath("//meta")
	  @headings = @doc.xpath("//h1")
	  @imgs = @doc.xpath("//img")
	  
	  #binding.pry
  	
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
	    	@results << result.new(tag, text, "Sua tag title possui "+text.length.to_s+" caracteres, muito próximo ao limite de 60 caracteres", "Atenção")
	    else
	    	@results << result.new(tag, text, "Sua tag title possui "+text.length.to_s+" caracteres e excedeu o limite de 60 caracteres", "Reprovado")
	    end
	    
	    #Testing for the presence of multiple commas, bars or keyword stuffing
	    if text.include? ','
	    	
	    	case 
	    		when text.count(',') == 1
	    			@results << result.new(tag, text, "Há suspeita de Keyword stuffing, vírgulas devem ser evitadas", "Atenção")
	    		when text.count(',') > 2
	    			@results << result.new(tag, text, "Foi detectado um número excessivo de vírgulas, caracterizando Keyword stuffing", "Reprovado")
	    		else
	    			@results << result.new(tag, text, "Não foram encontrados indícios de Keyword stuffing com vírgulas", "Aprovado")
	    	end
	    	
	    elsif text.include? '|'
	    	
	    	case
	    		when text.count('|') == 1
	    			@results << result.new(tag, text, "Separar o título da página e o título do site com pipe é recomendado", "Aprovado")
	    		when text.count('|') > 2
	    			@results << result.new(tag, text, "Excesso de pipes detectado, suspeita de Keyword Stuffing", "Reprovado")
	    		else
	    			@results << result.new(tag, text, "Sem pipes detecados. Separar o título da página e o título do site com pipe é recomendado", "Atenção")
	    	end
	    end
	    
	    #Testing with word separation
	    separatedText = text.split(' ')
	    
	    #Hash to count words
	    h = Hash.new(0)
	    
	    separatedText.each_with_index do |sT, index|
	    	
	    	#Counting words
	    	unless sT.length < 3
	    		h[sT] +=1
	    	end
	    	
	    	#string.include? => true/false
	    	
	    	#if sT.include? @domain
	    	#	@results << result.new(tag, text, "Nome do site deve ser similar ao domínio, ao final do título.", "Reprovado")
	    	#end
	    	
	    	
	    end
	    puts h
	    
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
		    	@results << result.new(tag, text, "Sua tag meta description possui "+text.length.to_s+" caracteres, muito próximo ao limite de 160 caracteres", "Atenção")
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
	  
	  #Checking if a heading tag <h1> exists
	  #Checking for the headings (h1 tags), if they have some matches to the contents of the title
	  
	  unless @headings.nil?
		  @headings.each do |heading|
		  	text = heading.text.to_s
		  	tag = "<h1>"
		  	matched = false
		  	
		  	h.each{|key, value|
		  		if heading.text.to_s.downcase.include? key.downcase
		  			matched = true
		  			break
		  		end
		  	}
		  	
		  	if matched == true
		  		@results << result.new(tag, text, "A tag heading(h1) possui palavra(s) iguais ao título", "Aprovado")
		  	else
		  		@results << result.new(tag, text, "A tag heading(h1) não possui palavras(s) iguais ao título", "Reprovado")
		  	end
		  	#binding.pry
		  end
		  
		 else
		 	@results << result.new("<h1>", "", "Não foi encontrado uma tag heading H1", "Reprovado")
		 end
	  #binding.pry
	  #Checking for the imgs
	  
	  #Checking for existence of "title" and "alt" attribute
	  totalImg = @imgs.count
	  tag = "<img>"
	  
	  @imgs.each do |img|
	  	
			
	  	text = img.attr('src')
	  	ckAlt = img.attr('alt')
	  	
	  	
	  	if ckAlt.nil?
	  		@results << result.new(tag, text, "Não foi encontrado o atributo ALT nesta imagem", "Reprovado")
	  	elsif ckAlt == ""
	  		@results << result.new(tag, text, "Não foi encontrado o atributo ALT nesta imagem", "Reprovado")
	  	else
	  		@results << result.new(tag, text, "Foi encontrado o atributo ALT nesta imagem", "Aprovado")
	  	end
	  	
	  	ckTitle = img.attr('title')
	  	unless ckTitle.nil?
	  		@results << result.new(tag, text, "Foi encontrado o atributo TITLE nesta imagem", "Aprovado")
	  	else
	  		@results << result.new(tag, text, "Não foi encontrado o atributo TITLE nesta imagem", "Atenção")
	  	end
	  	
	  	#binding.pry
	  end
	  
	  #Outside of any node
	  
	  #Processing console output
	  @sum = 0
	  @max = 0
	  
	  #Looping each result to calculate the final pontuation
	  
	  @results.each.with_index do |res, index|
	  	#puts res.tag + " | " + res.content + " | " + res.hint + " | " + res.score
	  	
	  	@temp = 0
	  	@max_temp = 0
	  	
	  	#Different weights for each tag, the title being the most important
	  	case res.tag
	  		when "<title>"
	  			@temp += sum_final(4, res.score)
	  			@max_temp += sum_final(4, "Aprovado")
	  		when "<meta>"
	  			@temp += sum_final(2, res.score)
	  			@max_temp += sum_final(2, "Aprovado")
	  		when "<h1>"
	  			@temp += sum_final(3, res.score)
	  			@max_temp += sum_final(3, "Aprovado")
	  		when "<img>"
	  			@temp += sum_final(1, res.score)
	  			@max_temp += sum_final(1, "Aprovado")
	  	end
	  	#binding.pry
	  	
	  	unless index == 0
	  		if index == 1
	  			@sum = (@sum.to_f + @temp) / 2
	  			@max = (@max.to_f + @max_temp)/ 2
	  		else
	  			@sum = ((@sum*index) + @temp.to_f)/(index+1)
	  			@max = ((@max*index) + @max_temp.to_f)/(index+1)
	  		end
	  		#binding.pry
	  	else
	  		@sum = @temp
	  		@max = @max_temp
	  	end
	  	
	  	#average(a) = 11
	  	#average(a,b) = (average(a)+b)/2
			#average(a,b,c) = (average(a,b)*2 + c)/3
	  	
	  end
	  
	  @sum = @sum.round(2)
	  @max = @max.round(2)
	  @percent_of_hits = ((@sum.fdiv(@max))*100).round(2)
	  
	  puts "SCORE FINAL: " + @sum.to_s
	  puts "SCORE MAX: " + @max.to_s
	  puts "Percent of hits: " + @percent_of_hits.to_s + "%."
	  
  end
  
  #Method to be called to calculate individual pontuation
  def sum_final(weight, score)
  	
  	case score
	  	when "Aprovado"
	  		return (10*weight)
	  	when "Atenção"
	  		return (4*weight)
	  	when "Reprovado"
	  		return (0*weight)
		end
	  	
	end
end


# http://robdodson.me/building-a-simple-scraper-with-nokogiri-in-ruby/