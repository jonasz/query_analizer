require 'rubygems'
require 'mongo'

require 'pp' #debug purposes
def debug (*xs)
    xs.each do |x|
        PP::pp(x, $>, 50)
    end
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
            result += [
                EvaluationResult.new(
                "$in operator with a large array (#{elems_no}) is inefficient",
                EvaluationResult::CRITICAL)
            ]
        end
        return result
    end

    def handle_negation (namespace, field, operator_arg)
        return [
            EvaluationResult.new(
            'Negation operators ($ne, $nin) are inefficient.',
            EvaluationResult::CRITICAL)
        ]
    end

    def handle_where (namespace, field, operator_arg)
        return [
            EvaluationResult.new(
            'javascript is slow, you should redesign your queries.',
            EvaluationResult::CRITICAL)
        ]
    end

    def handle_multiple(namespace, field, operator_arg)
        res = []
        operator_arg.each do |query|
            res += evaluate_query(query, namespace)
        end
        return res
    end

    def handle_not(namespace, field, operator_arg)
        res = [
            EvaluationResult.new(
            'Negation operator ($not) is inefficient',
            EvaluationResult::CRITICAL)
        ]
        res += self.handle_single_field(namespace, field, operator_arg)
        return res
    end

    def handle_nor(namespace, field, operator_arg)
        res = [
            EvaluationResult.new(
            'Negation operator ($nor) is inefficient',
            EvaluationResult::CRITICAL)
        ]
        res += self.handle_multiple(namespace, field, operator_arg)
        return res
    end

    def empty_handle(namespace, field, operator_arg)
        []
    end

    #TODO
    def check_for_indexes query_hash
        []
    end

    OPERATOR_HANDLERS_DISPATCH = {
        "_equality_check" => :empty_handle,

        # comparison
        "$all" => :empty_handle, #TODO
        "$in" => :handle_in,
        "$ne" => :handle_negation,
        "$nin" => :handle_negation,
        # we should not check for indexes here, the other method does that:
        "$lt" => :empty_handle,
        "$lte" => :empty_handle,
        "$gt" => :empty_handle,
        "$gte" => :empty_handle,

        # logical
        "$and" => :handle_multiple,
        "$or" => :handle_multiple,
        "$nor" => :handle_nor,
        "$not" => :handle_not,

        # element
        "$exists" => :empty_handle, #TODO
        "$mod" => :empty_handle, #TODO
        "$type" => :empty_handle, #TODO

        # javascript
        "$regex" =>  :empty_handle, #TODO
        "$where" => :handle_where,

        # geospatial
        "$box" => :empty_handle, #TODO
        "$near" => :empty_handle, #TODO
        "$within" => :empty_handle, #TODO

        # array
        "$elemMatch" => :empty_handle, #TODO
        "$size" => :empty_handle, #TODO
    }

    # handles operators for a single field, eg
    # {"$in" => [1.0, 2.0, 3.0], "$lt" => 12}
    # @param namespace specifies the collection
    # @param field specifies the field in the collection
    def handle_single_field(namespace, field, operators_hash)
        res = []
        operators_hash.each do |operator_str, val|
            method_symbol = OPERATOR_HANDLERS_DISPATCH[operator_str]
            if method_symbol.nil?
                raise "Unknown operator: '#{operator_str}'."
            end
            res += self.method( method_symbol ).call namespace, field, val
        end
        return res
    end

    # evaluates the whole query
    # @returns an array of EvaluationResult objects
    # query hash is the decoded query json, e.g.
    # {
    #   "B" => {"$in" => [24.0, 25.0]},
    #   "A" => {"$gt" => 27.3, "$lt" => 1000.0}
    # }
    def evaluate_query(query_hash, namespace)
        out = []

        # TODO
        out += check_for_indexes query_hash

        query_hash.each do |key, val|
            field = nil
            operator_hash = nil

            if key.start_with? '$' then
                #e.g. $or => [query1, query2, ...]
                operator_hash = { key => val }
            elsif val.is_a? Hash
                #e.g. "A" => {"$gt" : 13, "$lt" : 27}
                field = key
                operator_hash = val
            else
                #e.g. "A" => 27
                field = key
                operator_hash = { "_equality_check" => nil }
            end

            out += self.handle_single_field 'namespace', field, operator_hash
        end
        return out
    end

end #class Evaluator
