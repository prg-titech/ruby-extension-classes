    def singleton_method_added(name)
        # Make sure that we're not calling intercepting method definitions of wrappers etc.
        return if @__last_method_added == name || name[0, 2] == "__" || EXLCUDED_METHODS.include?(name)

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

        singleton_class.send(:alias_method, original_method_selector, name)

        define_singleton_method wrapper_method_selector do |*args, &block|
            LOG.info("Wrapper invoked for singleton method #{name}")
            LOG.info("Calling singleton #{original_method_selector}")

            # Activate class to which the method belongs
            Kernel.__with_layer(target_class) do
                send(original_method_selector, *args, &block)
            end
        end

        singleton_class.send(:alias_method, name, wrapper_method_selector)

        LOG.info("Added singleton method: #{name} with new alias #{original_method_selector}")
        @__last_method_added = nil
    end