require "set"
require_relative "testcase"
require "extension_classes"
require_relative "scenarios/scenario5"

class ScopeDefinitionTest < TestCase
	def test_reflexivity
		assert_equal([S5_A].to_set, S5_A.__scope.to_set)
	end

	def test_inheritance
		assert_equal([S5_B, S5_C].to_set, S5_B.__scope.to_set)
		assert_equal([S5_B, S5_C, S5_D, S5_E].to_set, S5_D.__scope.to_set)
	end

	def test_hierarchy
		assert_equal([S5_F, S5_F::S5_G, S5_F::S5_H, S5_A, S5_B].to_set, S5_F.__scope.to_set)
	end

	def test_hierarchy_inheritance_mixture
		assert_equal([S5_J, S5_J::S5_K, S5_J::S5_L, S5_M, S5_N, S5_O, S5_P, S5_Q].to_set, S5_J.__scope.to_set)
	end
end