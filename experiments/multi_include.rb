
module M
	def foo
		puts "M.foo"
	end
end

class A
	include M

	def foo
		puts "A.foo"
		super
	end
end

class B < A
	include M
end

class C < B
	include M

	def foo
		puts "B.foo"
		super
	end
end

# Module only imported once
C.new.foo

M.instance_method(:foo).bind(C.new).call

puts C.ancestors - [BasicObject]
