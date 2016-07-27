require "set"
require_relative "testcase"
require "extension_classes"
require_relative "scenarios/scenario10"

class ModuleTest < TestCase
	def test_module_scope
		assert_equal([S10_C, S10_B, S10_A].to_set, S10_C.__scope.to_set)
	end

	def test_module_include_refinement
		assert_equal([:replacement_A_B, :original_A_A], S10_C.new.call_A)
	end
end
