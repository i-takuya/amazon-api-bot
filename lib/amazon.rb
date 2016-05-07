# coding: utf-8
require 'amazon/ecs'
require 'date'
require 'csv'

class Amazon_Search
  BOOKS_CSV = "books.csv"
  def initialize(access_key,secret, tag)
    Amazon::Ecs.configure do |options|
      options[:AWS_access_key_id] = access_key
      options[:AWS_secret_key] = secret
      options[:associate_tag] = tag
    end
  end

  
  def search(page_from=1, page_to=1, keyword='eBooks', date=nil, detail=false)
    items = []
    res = nil
    i = 0;
    while i < (page_to - page_from + 1)
#    (page_to - page_from + 1).times do |i|
      begin
        unless detail
          res = Amazon::Ecs.item_search(keyword, :search_index => 'KindleStore', :country => 'jp', :sort => 'daterank', :item_page => (page_from + i + 1).to_s, :availability => 'Available')
        else
          date = Date.today if date.nil?
          power = 'pubdate: during ' + (date.month-2).to_s + '-' + date.year.to_s + ' and keywords: eBooks'
          puts power
          res = Amazon::Ecs.item_search(keyword, :search_index => 'Books', :country => 'jp', :item_page => (page_from + i + 1).to_s, :availability => 'Available', :power => power)
        end
        items.push(res)
      rescue
        puts 'Error for ' + i.to_s + ' retry'
        i = i - 1
        next
      ensure
        i = i + 1
        break if res.total_pages < i 
      end
    end
    
    @items = items
    # store data
    for res in @items do
      res.items.each do |item|
        store_csv(item)
      end
    end
  end

  def get_csv
    datas = CSV.read(BOOKS_CSV) if File.exists? BOOKS_CSV
    set_false(datas[1])
    datas
  end

  def set_false(item)
    tmp = []
    table = CSV.table BOOKS_CSV if File.exists? BOOKS_CSV
    table.delete_if do |row|
      row[1] == item[1]
    end
    
    File.open(BOOKS_CSV, 'w') do |f|
      f.write(table.to_csv)
    end
    CSV.open(BOOKS_CSV, "a") do |writer|
      writer << [false, item[1], item[2]]
    end
  end
  
  def store_csv(item)
    data = []
    data = CSV.read(BOOKS_CSV) if File.exists? BOOKS_CSV
    CSV.open(BOOKS_CSV, "a") do |writer|
      title = item.get('ItemAttributes/Title')
      url = item.get('DetailPageURL')
      writer << [true, title, url] unless (data.include?(['true', title, url]) || data.include?(['false', title, url])) 
    end
  end
  
  def show_item
    for res in @items do
      p res.total_pages.to_s + ", " + res.total_results.to_s
      
      res.items.each do |item|
        p item.get('ItemAttributes')
      end
    end
  end
end
