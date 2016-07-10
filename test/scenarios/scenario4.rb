# Scenarios for proceed
# A {B} --> B
class B
	def m_refinement
		[:original_B_B]
	end
end

class A
	def call_B
		B.new.m_refinement
	end

	partial

	class ::B
		def m_refinement
			[:refinement_B_A] + proceed
		end
	end
end

# C {B,A} --> A {B} --> B
class C
	def call_A_B_chain
		A.new.call_B
	end

	partial

	class ::B
		def m_refinement
			[:refinement_B_C] + proceed
		end
	end

	# Ensure that C remains active
	class ::A
		pass
	end
end