# coding: utf-8
require_relative 'lib/amazon'
require 'sinatra'
require 'sinatra/reloader'
get '/newbooks' do
  amazon = Amazon_Search.new('key', 'secret', 'tag')
  amazon.search(1,9, 'コミック', nil, true)
  @data = amazon.get_csv
  erb :index
end

