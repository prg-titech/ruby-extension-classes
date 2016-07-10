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
