# Example taken from paper (Section 3.2)

class S8_AddressBook
	class S8_Address
		def to_address
			self	
		end
	end

	class S8_ExternalConnectors
		class S8_LdapConnector
			def store(addr)
				addr.to_address
			end
		end
	end

	partial

	class ::String
		def to_address
			S8_Address.new
		end
	end
end

class S8_Networking
	class S8_Address
		def to_address
			self	
		end
	end

	class S8_Pinging
		def ping(addr)
			addr.to_address
		end
	end

	partial

	class ::String
		def to_address
			S8_Address.new
		end
	end
end
