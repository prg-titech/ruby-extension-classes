require 'debug_inspector'
require 'binding_of_caller'

class A
	def foo()
		puts "A::foo"
	end
end

class B < A
	def foo()
		puts "B::foo"
		print_my_class_and_call_super
	end
end

class C < B
	def foo()
		puts "C::foo"
		super
	end
end

def print_my_class_and_call_super
	cls = nil
	RubyVM::DebugInspector.open do |i| 
		cls = i.frame_class(2)
	end

	puts "CLS = #{cls}"
	cls.superclass.instance_method(:foo).bind(binding.of_caller(2).eval("self")).call
end

C.new.foo
