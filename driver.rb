#! /usr/bin/ruby
require 'rubygems'
require 'mongo'
require 'json'
require 'evaluator.rb'

include Mongo

def evaluate_str(query_json)
    e = Evaluator.new 'localhost', 27017
    query = JSON.parse(query_json)
    e.evaluate_query(query)
end

#query = '{ "A": { "$gt": 24.0 } }'
#query = '{ "A": { "$in": [ 24.0, 25.0 ] } }'
#query = '{ "A": { "$ne": 20.0 } }'
#query = '{ "A": { "$where": "javascript code here" } }'
query = '{ "A": { "$gt": 27.3 }, "B": { "$in": [ 24.0, 25.0 ] } }'

evaluation_results = evaluate_str query
puts
puts
puts "query: #{query}"
puts 'evaluation result:'
puts
evaluation_results.each do |res|
    puts "severity: #{res.severity}"
    puts "#{res.msg}"
    puts
end
