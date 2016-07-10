require "set"

class Module
	def __all_enclosing_classes
		# Note: Cannot use Module.nesting here, because it returns the nesting at the point of time when it was called
		classes = []
		last_class = Object

		name.split("::").each do |next_class|
			classes.push(last_class)
			last_class = last_class.const_get(next_class.to_sym)
		end

		classes
	end

	def __all_nested_classes
		constants.map do |const_sym|
			const_get(const_sym)
		end.find_all do |constant|
			constant.is_a?(Module)
		end
	end

    def __target_classes
        @__target_classes ||= Set.new
    end

    def __scope
        __target_classes + __all_nested_classes
    end
end

module Kernel
	def self.__deactivation_rule(klass)
		__layer_stack.reject! do |active_class|
			# Deactivate a class if it is not in the scope of the class whose method is called
			not active_class.__scope.include?(klass)
		end
	end

	def self.__activation_rule_get_all_classes_for(klass)
		# Return list of classes that should be activated (account for hierarchy)
		klass.__all_enclosing_classes + [klass]
	end
end