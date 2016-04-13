class SeoMainController < ApplicationController
  def index
  end

  def show
  	@url = params[:url]

  	require 'open-uri'
	@doc = Nokogiri::HTML(open(@url))

  end
end
