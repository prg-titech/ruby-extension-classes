# Class remains active during #call_B_C_chain
# A {B,C} --> B {} --> C {}
class S2_B
	def m_refinement
		:original_B_B
	end

	def call_C
		S3_C.new.m_refinement
	end
end

class S3_C
	def m_refinement
		:original_C_C
	end
end

class S2_A
	def call_B_C_chain
		S2_B.new.call_C
	end

	partial

	class ::S2_B
		def m_refinement
			:refinement_B_A
		end
	end

	class ::S3_C
		def m_refinement
			:refinement_C_A
		end
	end
end


# Class is deactivated during #call_E_F_chain
# D {F} --> E {} --> F {}
class S2_E
	def m_refinement
		:original_E_E
	end

	def call_F
		S3_F.new.m_refinement
	end
end

class S3_F
	def m_refinement
		:original_F_F
	end
end

class S2_D
	def call_E_F_chain
		S2_E.new.call_F
	end

	partial

	class ::S3_F
		def m_refinement
			:refinement_F_D
		end
	end
end


# Refinement is active only when called via H
# G {} --> H {I} --> I {}
# (reset stack)
# G {} --> I {}
class S2_I
	def m_refinement
		:original_I_I
	end
end

class S2_H
	def call_I
		S2_I.new.m_refinement
	end

	partial

	class ::S2_I
		def m_refinement
			:refinement_I_H
		end
	end
end

class S2_G
	def call_I
		S2_I.new.m_refinement
	end

	def call_H_I_chain
		S2_H.new.call_I
	end
end
