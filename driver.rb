#! /usr/bin/ruby
require 'rubygems'
require 'mongo'
require 'json'

include Mongo

#client = MongoClient.new
#db = client.db('jonaszdb')
#coll = db['ptaki']
#cursor = coll.find() 
#
#cursor.each do |x|
#    puts x.inspect
#end

require 'handlers.rb'

def quote_keys(x) # quick & dirty
    x.gsub('{ ', '{ "').gsub(':', '":')
end

def evaluate_operation(op_hash)
    if op_hash.count != 1 then raise "Wrong operator hash?" end

    e = Evaluator.new
    op_hash.each do |operator_str, val|
        return e.handle(operator_str, val)
    end
end

def find_bad(query)
    warnings = []
    query.each do |key, op|
        #puts "key: #{key.inspect}, op: #{op.inspect}"
        warnings += evaluate_operation op
    end
    return warnings
end

def evaluate(query_json)
    #query = JSON.parse(quote_keys query_json)
    query = JSON.parse(query_json)
    #puts query.inspect
    find_bad(query)
end

#query = '{ "A": { "$gt": 24.0 } }'
#query = '{ "A": { "$in": [ 24.0, 25.0 ] } }'
#query = '{ "A": { "$ne": 20.0 } }'
#query = '{ "A": { "$where": "javascript code here" } }'
query = '{ "A": { "$regex": "javascript code" }, "B": { "$in": [ 24.0, 25.0 ] } }'

evaluation_results = evaluate query
puts
puts
puts "query: #{query}"
puts 'evaluation result:'
puts
evaluation_results.each do |res|
    puts "priority: #{res.value}"
    puts "#{res.msg}"
    puts
end
