class C
	def foo
		puts 123
	end
end

module M
	refine C do
		def foo
			puts 456
		end
	end
end

	using M
class D


	def bar
		C.new.foo
	end
end

D.new.bar
