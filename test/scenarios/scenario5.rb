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
