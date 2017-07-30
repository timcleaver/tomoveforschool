#!/usr/bin/env ruby

require 'rubygems'
require 'csv'
require 'json'
require 'open-uri'
require 'hpricot'

BASE = 'http://auspost.com.au/postcode'

suburbs = []
rows = []
CSV.foreach('../data/open_spaces.csv', :headers => true, :return_headers => false) do |row|
  next if row.nil?
  next if row['ADDR3'].nil?
  next if row['ADDR3'].strip.eql? ''
  suburbs << row['ADDR3'].downcase.gsub(/ /, '-')
  rows << row
end

postcodes = {}
suburbs.uniq.each do |suburb|
  page = Hpricot(open(BASE + '/' + suburb).read)
  table = page/"//table[@class~='resultsList']"
  postcode = (table/"td[@class='first']/a").select { |a|
    a['href'] =~ /qld/
  }.map { |a|
    a.inner_html
  }.first
  STDERR.puts "#{suburb} -> #{postcode}"
  postcodes[suburb] = postcode
end

spaces = []
rows.each do |row|
  spaces << {
    name: row['NAME'],
    address: row['ADDRESS'],
    suburb: row['ADDR3'],
    postcode: postcodes[row['ADDR3'].downcase.gsub(/ /, '-')],
    area_square_meters: row['AREA_SQ_M'],
    category: row['RFOS_CATEGORY'],
    sub_category: row['RFOS_SUB_CATEGORY']
  }
end

puts JSON.pretty_generate(spaces)

