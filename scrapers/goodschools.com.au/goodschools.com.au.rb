#!/usr/bin/env ruby

require 'rubygems'
require 'phantomjs'
require 'watir-webdriver'
require 'chronic'
require 'csv'
require 'awesome_print'
require 'date'
require 'open-uri'
require 'thread'
require 'json'

BASE = 'https://www.goodschools.com.au/compare-schools'

regions = [
  "in-Canberra-ACT",
  "in-Sydney-NSW",
  "in-Brisbane-QLD",
  "in-Adelaide-SA",
  "in-Hobart-TAS",
  "in-Melbourne-VIC",
  "in-Perth-WA",
  "in-Darwin-NT"
]

CSV($stdout) do |csv|
  csv << [ 'school' ]

  browser = Watir::Browser.new :phantomjs
  regions.each do |region|
    begin
      browser.goto(BASE + '/' + region)
    rescue
      sleep 1
      retry
    end
    STDERR.puts region
    schools = browser.divs(:class => 'row-search-result').select { |s|
      s.h3.exists?
    }.map { |s|
      [s.h3.a.inner_html, s.h3.a.href]
    }
    pages = browser.ul(:class => 'pagination').lis[1..-2].select {
      |li| li.a.exists?
    }.map { |li|
      li.a.href
    }
    STDERR.puts schools.size
    schools.each { |school| csv << [ school[0] ] }
    pages.each do |page|
      STDERR.puts page
      begin
        browser.goto page
      rescue
        sleep 1
        retry
      end
      schools = browser.divs(:class => 'row-search-result').select { |s|
        s.h3.exists?
      }.map { |s|
        [s.h3.a.inner_html, s.h3.a.href]
      }
      STDERR.puts schools.size
      schools.each { |school| csv << [ school[0] ] }
    end
  end
end
