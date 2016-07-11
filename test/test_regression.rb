require_relative "testcase"
require "extension_classes"
require_relative "scenarios/scenario9"

class RegressionTests < TestCase
	def test_call_down_the_hierarchy
		assert_equal(:bar, S9_B.new.foo)
	end

	def test_initialize
		S9_C.new
	end

	def test_overridden_method
		assert_equal(3, S9_E.new.foo)
	end
end
