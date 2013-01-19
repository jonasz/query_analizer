#! /usr/bin/ruby
require 'evaluator'

#query = {"B"=>{"$in"=>[24.0, 25.0, 28.0, 29.0]}, "A"=>{"$gt"=>27.3}}
#query = { "$or"=> [
#    { "A"=> { "$gt"=> 25.0 } },
#    { "b"=> { "$in"=> [ 1.0, 2.0, 3.0, 4.0 ] } }
#] }
#query = {"B"=>{"$not" => {"$in"=>[24.0, 25.0, 28.0, 29.0]} } }
#query = { "$nor"=> [
    #{ "A"=> { "$gt"=> 25.0 } },
    #{ "b"=> { "$in"=> [ 1.0, 2.0, 3.0, 4.0 ] } }
#] }
#query = {"A" => 23.0}
query = {"A" => {"$in" => [1,2,3,4], "$lt" => 30.0} }

e = Evaluator.new 'localhost', 27017
evaluation_results = e.evaluate_query(query, 'dbname.collname')

debug 'query:', query
puts
puts 'evaluation result:'
puts
evaluation_results.each do |res|
    puts "severity: #{res.severity}"
    puts "#{res.msg}"
    puts
end
