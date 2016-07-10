require_relative "testcase"
require "extension_classes"
require_relative "scenarios/scenario4"

class ScopeReflexivityTest < TestCase
	def test_proceed_to_base
		assert_equal([:refinement_B_A, :original_B_B], A.new.call_B)
	end

	def test_proceed_to_next_layer_then_base
		assert_equal([:refinement_B_A, :refinement_B_C, :original_B_B], C.new.call_A_B_chain)
	end
end
