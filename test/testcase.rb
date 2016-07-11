require "test/unit"

class TestCase < Test::Unit::TestCase
	def setup
		assert_stack_empty
	end

	def assert_stack_empty
		stack_without_self = Kernel.__layer_stack - [self.class, Object]
		assert(stack_without_self.empty?, "Composition stack not empty: #{stack_without_self}")
	end
end