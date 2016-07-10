require_relative "testcase"
require "extension_classes"
require_relative "scenarios/scenario2"
require_relative "scenarios/scenario1"

class ScopeDynamicTest < TestCase
	def test_remain_active
		assert_equal(:refinement_C_A, S2_A.new.call_B_C_chain)
	end

	def test_deactivation
		assert_equal(:original_F_F, S2_D.new.call_E_F_chain)
	end

	def test_stack_restore_on_method_return
		assert_equal(:refinement_I_H, S2_G.new.call_H_I_chain)
		assert_equal(:original_I_I, S2_G.new.call_I)
	end

	def test_indirect_call_within_class
		assert_equal(:original_A_A, S1_A.new.call_A_refinement)
		assert_equal(:refinement_A_B, S1_B.new.call_A_refinement_indirect)
	end
end