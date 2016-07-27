class S10_A
	def m_replacement
		[:original_A_A]
	end
end

module S10_B
	partial

	class ::S10_A
		def m_replacement
			[:replacement_A_B] + proceed
		end
	end
end

class S10_C
	include S10_B

	def call_A
		S10_A.new.m_replacement
	end
end
