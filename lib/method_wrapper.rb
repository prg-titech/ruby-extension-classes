require "binding_of_caller"

class Module
    LOG = Kernel::LOG
    EXLCUDED_METHODS = [:method_added, :singleton_method_added, :is_defining_partial?]
    EXCLUDED_CLASSES = [IO]
    # Do not mess with the testing framework
    EXCLUDED_CLASSES_START_WITH = ["Test::"]

    alias_method(:__original_private, :private)
    alias_method(:__original_protected, :protected)
    alias_method(:__original_public, :public)

    def private(*args)
        @__definining_partial = false
        __original_private(*args)
    end

    def protected(*args)
        @__definining_partial = false
        __original_protected(*args)
    end

    def public(*args)
        @__definining_partial = false
        __original_public(*args)
    end

    def partial
        @__definining_partial = true
    end

    def pass
        sender = binding.of_caller(2).eval("self")

        if sender.is_a?(Module) && sender.is_defining_partial?
            sender.__target_classes.add(self)
        end
    end

    def method_added(name)
        # Make sure that we're not calling intercepting method definitions of wrappers etc.
        return if @__last_method_added == name || name[0, 2] == "__" || EXLCUDED_METHODS.include?(name)
        return if EXCLUDED_CLASSES.include?(self)
        return if EXCLUDED_CLASSES_START_WITH.any? do |prefix|
            self.to_s.start_with?(prefix)
        end

        target_class = self

        # Detect if we are defining a singleton method or a partial method
        original_method_selector = nil
        sender = binding.of_caller(2).eval("self")

        if sender.is_a?(Module) && sender.is_defining_partial?
            original_method_selector = Kernel.__partial_selector(name, sender)
            sender.__target_classes.add(target_class)
        else
            original_method_selector = Kernel.__original_selector(name)
        end

        wrapper_method_selector = :"__#{name}_wrapper"
        @__last_method_added = name

        alias_method(original_method_selector, name)

        define_method wrapper_method_selector do |*args, &block|
            LOG.info("Wrapper invoked for method #{target_class.to_s}.#{name}")

            # ------- BEGIN METHOD WRAPPER -------

            runtime_class = self.class
            selector = name
            __lookup_state = LookupState.new(current_class: target_class, runtime_class: runtime_class,
                runtime_layer: Kernel.__layer_stack.first, selector: selector)

            # Method lookup
            method = __lookup_state.get_method_for_this_state

            if method == nil
                BasicObject.instance_method(:method_missing).bind(self).call(selector, *args, &block)
            else
                LOG.info("Calling #{method.name}")

                # Deactivation of classes
                Kernel.__deactivation_rule(runtime_class)
                
                # Activate class to which the method belongs
                Kernel.__with_layer(runtime_class) do
                    method.bind(self).call(*args, &block)
                end
            end

            # ------- END METHOD WRAPPER -------
        end

        alias_method(name, wrapper_method_selector)

        LOG.info("Added method: #{name} with new alias #{original_method_selector}")
        @__last_method_added = nil
    end

    def is_defining_partial?
        @__definining_partial || false
    end
end