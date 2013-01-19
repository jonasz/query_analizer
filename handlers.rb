


class EvaluationResult
    def initialize(msg, value)
        @msg = msg
        @value = value
    end
    attr_reader :msg, :value
    #attr_accessor :msg, :value
end

class Evaluator
    OK = 0
    BAD = 1
    VERY_BAD = 2
    CRITICAL = 3
    MAX_IN_ARRAY = 1

    def handle_in (hash_op)
        #puts "HANDLE IN"
        #puts hash_op.inspect
        if hash_op.count > MAX_IN_ARRAY then
            return [EvaluationResult.new(
                '$in operator with a large array is inefficient',
                CRITICAL
            )]
        else
            return [EvaluationResult.new(
                ':)',
                OK
            )]
        end
    end

    def handle_negation (hash_op)
        return [EvaluationResult.new(
            'negation operator is inefficient',
            CRITICAL
        )]
    end

    def handle_where (hash_op)
        return [EvaluationResult.new(
            'javascript is slow, you should redesign your queries',
            CRITICAL
        )]
    end

    def handle_regexp(hash_op)
        return [
            EvaluationResult.new(
                'REGEX 1',
                CRITICAL),
            EvaluationResult.new(
                'REGEX 2',
                BAD),
        ]
    end

    OPERATORS = {
        "$in" => :handle_in,
        "$ne" => :handle_negation,
        "$not" => :handle_negation,
        "$nin" => :handle_negation,
        "$where" => :handle_where,
        "$regex" => :handle_regexp,
    }

    def handle(op_str, hash_op)
        method_symbol = OPERATORS[op_str]
        return self.method( method_symbol ).call hash_op
    end
end #class Evaluator
