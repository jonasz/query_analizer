require 'rubygems'
require 'mongo'

#debug purposes
require 'pp'

def debug (x)
    PP::pp(x, $>, 50)
end

class EvaluationResult
    BAD = 1
    VERY_BAD = 2
    CRITICAL = 3
    def initialize(msg, severity)
        @msg = msg
        @severity = severity
    end
    attr_reader :msg, :severity
end

class Evaluator
    #severity levels:

    def initialize(addr, port)
        @addr = addr
        @port = port
    end

    def getDb(dbname)
        cl = Mongo::MongoClient.new @addr, @port
        return cl.db(dbname)
    end
    
    def getColl(namespace)
        db_name, collection_name = namespace.split('.',2)
        db = self.getDb(db_name)
        coll = db['collection_name']
    end

    # TODO
    def getIndexInformation(namespace)
        coll = getColl(namespace)
        debug coll.index_information
    end

    #
    # the operator handlers follow
    # every handler returns an array of EvaluationResult objects
    # depending on the following arguments
    # namespace - specifies the collection
    # field (self explanatory)
    # operator_arg - the query arguments, specific to different operators
    #

    MAX_IN_ARRAY = 3 #small for testing purposes
    def handle_in (namespace, field, operator_arg)
        result = []
        elems_no = operator_arg.count
        if elems_no > MAX_IN_ARRAY then
            result += [EvaluationResult.new(
                "$in operator with a large array (#{elems_no}) is inefficient",
                EvaluationResult::CRITICAL
            )]
        end
        return result
    end

    def handle_negation (namespace, field, operator_arg)
        return [EvaluationResult.new(
            'Negation operators ($ne, $nin) $ are inefficient.',
            EvaluationResult::CRITICAL
        )]
    end

    def handle_where (namespace, field, operator_arg)
        return [EvaluationResult.new(
            'javascript is slow, you should redesign your queries.',
            EvaluationResult::CRITICAL
        )]
    end

    def empty_handle(namespace, field, operator_arg)
        []
    end

    #TODO
    def check_for_indexes query_hash
        []
    end

    OPERATOR_HANDLERS_DISPATCH = {
        "$all" => :empty_handle, #TODO
        "$gt" => :empty_handle, #TODO
        "$gte" => :empty_handle, #TODO
        "$in" => :handle_in,
        "$lt" => :empty_handle, #TODO
        "$lte" => :empty_handle, #TODO
        "$ne" => :handle_negation,
        "$nin" => :handle_negation,

        # logical
        "$and" => :empty_handle, #TODO
        "$nor" => :empty_handle, #TODO
        "$not" => :empty_handle, #TODO
        "$or" => :empty_handle, #TODO

        # element
        "$exists" => :empty_handle, #TODO
        "$mod" => :empty_handle, #TODO
        "$type" => :empty_handle, #TODO

        # javascript
        "$regex" =>  :empty_handle, #TODO
        "$where" => :empty_handle, #TODO

        # geospatial
        "$box" => :empty_handle, #TODO
        "$near" => :empty_handle, #TODO
        "$within" => :empty_handle, #TODO

        # array
        "$elemMatch" => :empty_handle, #TODO
        "$size" => :empty_handle, #TODO
    }

    # handles a single operator, e.g.
    # {"$in" => [1.0, 2.0, 3.0]}
    # @param namespace specifies the collection
    # @param field specifies the field in the collection
    def handle_single(namespace, field, operator_hash)
        if operator_hash.count != 1 then raise "Wrong operator hash?" end

        operator_hash.each do |operator_str, val|
            method_symbol = OPERATOR_HANDLERS_DISPATCH[operator_str]
            return self.method( method_symbol ).call namespace, field, val
        end
    end

    # evaluates the whole query
    # @returns an array of EvaluationResult objects
    # query hash is the decoded query json, e.g.
    # { 
    #   "B" => {"$in" => [24.0, 25.0]},
    #   "A" => {"$gt" => 27.3}}
    # }
    def evaluate_query(query_hash, namespace)
        debug query_hash
        out = []

        # TODO
        out += check_for_indexes query_hash

        query_hash.each do |field, op|
            out += self.handle_single 'namespace', field, op
        end
        return out
    end

end #class Evaluator
