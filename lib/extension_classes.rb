if RUBY_VERSION != "2.3.0"
	puts "Ruby version #{RUBY_VERSION} not supported. Expected MRI 2.3.0!"
	exit
end

require_relative "logging"
require_relative "composition_stack"
require_relative "integration"
require_relative "method_lookup"
require_relative "scope"
require_relative "method_wrapper"
