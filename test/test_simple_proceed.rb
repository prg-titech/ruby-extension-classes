require_relative "testcase"
require "extension_classes"
require_relative "scenarios/scenario4"

class ScopeReflexivityTest < TestCase
	def test_proceed_to_base
		assert_equal([:refinement_B_A, :original_B_B], S4_A.new.call_B)
	end

	def test_proceed_to_next_layer_then_base
		assert_equal([:refinement_B_A, :refinement_B_C, :original_B_B], S4_C.new.call_A_B_chain)
	end

	def test_proceed_as_super
		assert_equal([:original_E_E, :original_D_D], S4_E.new.m_original)
	end
end
