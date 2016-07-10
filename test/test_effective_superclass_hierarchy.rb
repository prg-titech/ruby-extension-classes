require_relative "testcase"
require "extension_classes"
require_relative "scenarios/scenario6"

class EffectiveSuperclassHierarchyTest < TestCase
	def test_hierarchy
		#assert_equal([:refinement_CPr_BPr, :refinement_CPr_B, :refinement_CPr_APr, 
		#	:original_CPr_CPr, :refinement_C_A, :original_C_C], S6_A_Prime.new.call_BPr_CPr_chain)
	end
end
