require "test/unit"

class TestCase < Test::Unit::TestCase
	def setup
		assert_stack_empty
	end

	def assert_stack_empty
		assert(Kernel.__layer_stack.empty?, "Composition stack not empty")
	end
end