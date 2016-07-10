# Scope definition tests

# Reflexivity
class S5_A

end

# Inheritance Scoping
class S5_C

end

class S5_E

end

class S5_B
	partial

	class ::S5_C
		pass
	end
end

class S5_D < S5_B
	partial

	class ::S5_E
		pass
	end
end

# Hierarchical Scoping
class S5_F
	class S5_G
		partial

		class ::S5_A
			pass
		end
	end

	class S5_H
		partial

		class ::S5_B
			pass
		end
	end
end

# Hierarchical Scoping + Inheritance Scoping
class S5_N; end
class S5_O; end
class S5_P; end
class S5_Q; end

class S5_M
	partial

	class ::S5_N
		pass
	end
end

class S5_J
	class S5_K < S5_M
		partial

		class ::S5_O
			pass
		end
	end

	class S5_L
		partial

		class ::S5_P
			pass
		end
	end

	partial

	class ::S5_Q
		pass
	end
end
