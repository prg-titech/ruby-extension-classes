require "binding_of_caller"

class Module
    LOG = Kernel::LOG
    EXLCUDED_METHODS = [:method_added, :singleton_method_added, :is_defining_partial?]
    EXCLUDED_CLASSES = [IO]

    alias_method(:__original_private, :private)
    alias_method(:__original_protected, :protected)
    alias_method(:__original_public, :public)

    def private
        @__definining_partial = false
        __original_private
    end

    def protected
        @__definining_partial = false
        __original_protected
    end

    def public
        @__definining_partial = false
        __original_public
    end

    def partial
        @__definining_partial = true
    end

    def method_added(name)
        # Make sure that we're not calling intercepting method definitions of wrappers etc.
        return if @__last_method_added == name || name[0, 2] == "__" || EXLCUDED_METHODS.include?(name)
        return if EXCLUDED_CLASSES.include?(self)

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

            # Find top-most partial method in layer stack
            layer = Kernel.__layer_stack.reverse_each.detect do |next_layer|
                target_class.instance_methods.include?(Kernel.__partial_selector(name, next_layer))
            end

            partial_selector = if layer == nil then Kernel.__original_selector(name) else Kernel.__partial_selector(name, layer) end
            LOG.info("Calling #{partial_selector}")

            # Deactivation of classes
            Kernel.__deactivation_rule(target_class)
            
            # Activate class to which the method belongs
            Kernel.__with_layer(target_class) do
                target_class.instance_method(partial_selector).bind(self).call(*args, &block)
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