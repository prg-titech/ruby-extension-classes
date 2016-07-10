require_relative "testcase"
require "extension_classes"
require_relative "scenarios/scenario1"

class ScopeReflexivityTest < TestCase
	def test_adapated
		assert_equal(:original_A_A, S1_B.new.call_original)
		assert_equal(:addition_A_B, S1_B.new.call_addition)
		assert_equal(:refinement_A_B, S1_B.new.call_refinement)
	end

	def test_unadapted
		assert_equal(:original_A_A, S1_A.new.m_original)
		assert_equal(:original_A_A, S1_A.new.m_refinement)
	end
end
