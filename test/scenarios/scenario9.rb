class S9_A
	def foo
		bar
	end
end

class S9_B < S9_A
	def bar
		:bar
	end
end

class S9_C
	def initialize

	end
end

class S9_D
	def foo
		1
	end
end

class S9_E < S9_D
	def foo
		proceed + 2
	end
end