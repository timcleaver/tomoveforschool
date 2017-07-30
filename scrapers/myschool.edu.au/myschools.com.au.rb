#!/usr/bin/env ruby

require 'rubygems'
require 'phantomjs'
require 'watir-webdriver'
require 'hpricot'
require 'chronic'
require 'csv'
require 'awesome_print'
require 'date'
require 'open-uri'
require 'thread'
require 'json'
require 'rest-client'
require 'uri'
require 'thread'

BASE = 'https://myschool.edu.au'
PRESEARCH = BASE + '/SchoolSearch/GlobalSearch?count=20&term='
SEARCH = BASE + '/Home/GenericSearch'

MAX_THREADS = 10
# create a queue so we can download pages while we are parsing them
queue = SizedQueue.new MAX_THREADS
# use a Mutex to protect the array so only one thread can add a row at a time
mutex = Mutex.new
# save the school data
schools = []

threads = (1..MAX_THREADS).map do |i|
  Thread.new(queue, mutex) do |q, m|
    until (q == (line = q.deq))
      STDERR.puts (PRESEARCH + URI::encode(line))
      data = open(PRESEARCH + URI::encode(line)).read
      next if data.size < 1
      result = JSON.parse(data)
      next if result.nil?
      result = result.first
      next if result.nil?
      r = RestClient.post(SEARCH, {
        SchoolNameGlobal: result['SchoolDetails'],
        SMCLID: result['SMCLID'],
        SMCLDisplayID: ''
      }) { |response, request, result, &block|
        if [301, 302, 307].include? response.code
          redirected_url = response.headers[:location]
        else
          response.return!(request, result, &block)
        end
      }
      page = Hpricot(open(BASE + r).read)
      table = (page/"//table[@class='profile-table']")[0..2]
      properties = {}
      (table/"tr").each do |tr|
        header = (tr/"th").inner_html
                    .strip
                    .split(/\r/)[0]
                    .downcase
                    .gsub(/ /, '_')
                    .gsub(/,/, '')
        properties[header] = (tr/"td").inner_html.strip
      end

      page = Hpricot(open(BASE + r.gsub('SchoolProfile', 'ResultsInNumbers')).read)
      table = page/"//table[@class='results-in-numbers']"
      (table/"tr[@class='selected-school-row']").each do |tr|
        tds = (tr/"td")
        m.synchronize {
          schools << properties.merge({
              school: result['SchoolDetails'],
              school_name: result['SchoolDetails'].split(/,/)[0],
              postcode: result['SchoolDetails'].split(/,/)[-1],
              state: result['SchoolDetails'].split(/,/)[-2],
              smclid: result['SMCLID'],
              year: 2016,
              grade: (tr/"th").inner_html.gsub(/Year /, ''),
              reading: begin (tds[0]/"span[@class='avg']").inner_html rescue nil end,
              writing: begin (tds[1]/"span[@class='avg']").inner_html rescue nil end,
              spelling: begin (tds[2]/"span[@class='avg']").inner_html rescue nil end,
              grammer_punctuation: begin (tds[3]/"span[@class='avg']").inner_html rescue nil end,
              numeracy: begin (tds[4]/"span[@class='avg']").inner_html rescue nil end
          })
        }
      end
    end
  end
end

# fill the queue
ARGF.readline
ARGF.each do |line|
  line = line.gsub(/\n/, '')
  queue << line
end
puts JSON.pretty_generate schools

