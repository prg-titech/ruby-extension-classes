# Example taken from paper (Fig. 7: Effective Superclass Hierarchy Example)
# A {C, C'} --> B {C'} --> C'

class S6_C
	def m_refinement
		[:original_C_C]
	end
end

class S6_C_Prime < S6_C
	def m_refinement
		[:original_CPr_CPr] + proceed
	end
end

class S6_B
	partial

	class ::S6_C_Prime
		def m_refinement
			[:refinement_CPr_B] + proceed
		end
	end
end

class S6_B_Prime < S6_B
	def call_CPr
		S6_C_Prime.new.m_refinement
	end

	partial

	class ::S6_C_Prime
		def m_refinement
			[:refinement_CPr_BPr] + proceed
		end
	end
end


class S6_A
	partial

	class ::S6_C
		def m_refinement
			[:refinement_C_A] + proceed
		end
	end
end

class S6_A_Prime < S6_A
	def call_BPr_CPr_chain
		S6_B_Prime.new.call_CPr
	end

	partial

	class ::S6_C_Prime
		def m_refinement
			[:refinement_CPr_APr] + proceed
		end
	end

	class ::S6_B_Prime
		# Ensure that layer remains active
		pass
	end
end

