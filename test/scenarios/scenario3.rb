# Scenarios for hierarchical scoping
# A{C}::B --> C
class S3_C
	def m_refinement
		:original_C_C
	end
end

class S3_A
	class S3_B
		def call_refinement
			S3_C.new.m_refinement
		end
	end

	partial

	class ::S3_C
		def m_refinement
			:refinement_C_A
		end
	end
end


# False hierarchy
class S3_D
	def call_E_F_chain
		S3_E::S3_F.new.call_refinement
	end

	partial

	class ::S3_C
		def m_refinement
			:refinement_C_A
		end
	end
end

class S3_E
	class S3_F
		def call_refinement
			S3_C.new.m_refinement
		end
	end
end
