require_relative "testcase"
require "extension_classes"
require_relative "scenarios/scenario8"

class AddrBookNetworkingExampleTest < TestCase
	def test_address_book
		assert_equal(S8_AddressBook::S8_Address, S8_AddressBook::S8_ExternalConnectors::S8_LdapConnector.new.store("Ookayama").class)
	end

	def test_networking
		assert_equal(S8_Networking::S8_Address, S8_Networking::S8_Pinging.new.ping("127.0.0.1").class)
	end
end
