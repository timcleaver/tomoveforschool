#!/usr/bin/env ruby

require 'rubygems'
require 'csv'
require 'json'

postcodes = {}
CSV.foreach('../data/2016Census_G01_QLD_POA.csv', :headers => true, :return_headers => false) do |row|
  postcode = row[0].gsub(/POA/, '')
  if not postcodes.key? postcode
    postcodes[postcode] = {
      postcode: postcode
    }
  end
  p = postcodes[postcode]
  p['age_group_0_4'] = row['Age_0_4_yr_P']
  p['age_group_5_14'] = row['Age_5_14_yr_P']
end

CSV.foreach('../data/2016Census_G02_QLD_POA.csv', :headers => true, :return_headers => false) do |row|
  postcode = row[0].gsub(/POA/, '')
  if not postcodes.key? postcode
    postcodes[postcode] = {
      postcode: postcode
    }
  end
  p = postcodes[postcode]
  p['average_household_size'] = row['Average_household_size']
  p['median_rent'] = row['Median_rent_weekly']
end

CSV.foreach('../data/2016Census_G29_QLD_POA.csv', :headers => true, :return_headers => false) do |row|
  postcode = row[0].gsub(/POA/, '')
  if not postcodes.key? postcode
    postcodes[postcode] = {
      postcode: postcode
    }
  end
  p = postcodes[postcode]
  p['total_number_households'] = row['HI_1_149_Tot']
end

CSV.foreach('../data/2016Census_G33_QLD_POA.csv', :headers => true, :return_headers => false) do |row|
  postcode = row[0].gsub(/POA/, '')
  if not postcodes.key? postcode
    postcodes[postcode] = {
      postcode: postcode
    }
  end
  p = postcodes[postcode]
  p['number_renters'] = row['R_Tot_Total']
  p['number_owned_outright'] = row['O_OR_Total']
  p['number_own_mortgage'] = row['O_MTG_Total']
end
puts JSON.pretty_generate(postcodes)

