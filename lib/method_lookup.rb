require "binding_of_caller"

class Object
    def proceed(*args, &block)
        # TODO: this code works only for instance methods at the moment

        current_method_selector = binding.of_caller(1).eval("__callee__")
        is_base = current_method_selector.to_s.end_with?("_original")

        # TODO: have to find out in which class a method is defined to do "super" properly
        target_object = target_class = binding.of_caller(1).eval("self")
        if !target_class.is_a?(Module)
            target_class = target_class.class
        end

        if is_base
            # Invoke super method
            LOG.warn("Missing: is_base case, have to do super call")
            #method_selector = current_method_selector[2..-1].split("_").first
            #target_class.superclass.instance_method(method_selector.to_sym).bind(target_object).call(*args, &block)
        else
            # Invoke next partial method (or base method)
            LOG.info("Current method selector: #{current_method_selector}")

            # Can assume that every layer is activated only once
            current_owner = current_method_selector.to_s.split("_partial_").last
            current_layer_index = Kernel.__layer_stack.find_index do |layer|
                layer.to_s.gsub("::", "_") == current_owner
            end

            method_selector = Kernel.__extract_selector_from_mangled_partial(current_method_selector)

            # Find next partial method in layer stack
            layer = Kernel.__layer_stack.slice(current_layer_index + 1, Kernel.__layer_stack.size()).detect do |next_layer|
                target_class.instance_methods.include?(Kernel.__partial_selector(method_selector, next_layer))
            end

            partial_selector = if layer == nil then Kernel.__original_selector(method_selector) else Kernel.__partial_selector(method_selector, layer) end
            LOG.info("Calling #{partial_selector}")

            # Activate class to which the method belongs
            Kernel.__with_layer(target_class) do
                target_class.instance_method(partial_selector).bind(target_object).call(*args, &block)
            end
        end
    end
end

module Kernel
    # Retrieves the next method (UnboundMethod) that should be called
    def __get_next_method(current_class, runtime_class, selector, current_layer = nil)
        if current_class == nil
            # Lookup failed
            return nil
        end

        if current_layer == nil
            # base method
            mangled_selector = __original_selector(selector)
            if current_class.instance_methods.include?(mangled_selector)
                # found base method
                current_class.instance_method[mangled_selector]
            else
                # look for next partial method in superclass
                next_layer = __layer_stack.first
                next_class = __get_superclass(current_class, runtime_class)
                # next_layer == nil indicates "check for base method next"
                __get_next_method(next_class, runtime_class, selector, next_layer)
            end
        else
            # look for the next partial method/base method of current_class
            mangled_selector = __partial_selector(selector, next_layer)
            if current_class.instance_methods.include?(mangled_selector)
                # found partial method
                current_class.instance_method[mangled_selector]
            else
                # look for next partial method
                next_layer = __get_next_layer(current_layer)
                # next_layer == nil indicates "check for base method next"
                __get_next_method(current_class, runtime_class, selector, next_layer)
            end
        end
    end

    # Returns the layer underneath current_layer, or nil if there are no more layers
    def __get_next_layer(current_layer)
        __layer_stack[__layer_stack.find_index(current_layer) + 1]
    end

    # Returns the next superclass/supermodule of klass in the hierarchy of runtime_class
    def __get_superclass(klass, runtime_class)
        # Don't use "superclass" method to account for modules
        superclasses = runtime_class.ancestors - [BasicObject]
        superclasses[superclass.find_index(klass) + 1]
    end
end

