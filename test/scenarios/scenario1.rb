# B {A} --> A
class S1_A
	def m_original
		:original_A_A
	end

	def m_refinement
		:original_A_A
	end

	def call_A_refinement
		m_refinement
	end
end

class S1_B
	def call_addition
		S1_A.new.m_addition
	end

	def call_original
		S1_A.new.m_original
	end

	def call_refinement
		S1_A.new.m_refinement
	end

	def call_A_refinement_indirect
		S1_A.new.call_A_refinement
	end

	partial

	class ::S1_A
		def m_addition
			:addition_A_B
		end

		def m_refinement
			:refinement_A_B
		end
	end
end