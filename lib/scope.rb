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

    FORBIDDEN_SUPERCLASS_SCOPING = [Object, BasicObject, nil]
    def __scope
        queue = [self]
        scope = Set.new
        visited = Set.new

        #return scope

        while not queue.empty?
            next_class = queue.pop

            # Avoid recursion to same class, which can happen if superclass is an enclosing class
            if not visited.include?(next_class)
                # Reflexivity
                scope.add(next_class)
                # Dynamic Scoping
                scope += next_class.__target_classes

                if next_class.is_a?(Class)
                    if not FORBIDDEN_SUPERCLASS_SCOPING.include?(next_class.superclass)
                        # Special rule: do not include Object
                        queue.push(next_class.superclass)
                    end

                    # Push all included modules
                    if next_class != BasicObject
                        queue += next_class.included_modules - next_class.superclass.included_modules
                    end
                end

                # Hierarchical Scoping
                next_class.__all_nested_classes.each do |klass|
                    # TODO: account for modules
                    if klass.is_a?(Class)
                        queue.push(klass)
                    end
                end

                visited.add(next_class)
            end
        end

        scope
    end
end

module Kernel
	# Invoked if a method in klass is called
	def self.__deactivation_rule(klass)
		__layer_stack.reject! do |active_class|
			# Deactivate a class if it is not in the scope of the class whose method is called
			# Reject if $klass \not\in scope(active_class)$
			if active_class.__scope.include?(klass)
				false
			else
				LOG.info("[X] Deactivating #{active_class}, not in #{klass} ∉ scope(#{active_class}) = #{active_class.__scope.to_a}")
				true
			end
		end
	end

	def self.__activation_rule_get_all_classes_for(klass)
		# Return list of classes that should be activated (account for hierarchy)
		klass.__all_enclosing_classes + [klass]
	end
end