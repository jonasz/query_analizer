#! /usr/bin/ruby
require 'evaluator'

query = {"B"=>{"$in"=>[24.0, 25.0, 28.0, 29.0]}, "A"=>{"$gt"=>27.3}}

e = Evaluator.new 'localhost', 27017
evaluation_results = e.evaluate_query(query, 'dbname.collname')

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
