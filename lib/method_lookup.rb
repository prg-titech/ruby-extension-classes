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
            layer = Kernel.__layer_stack.slice(0, current_layer_index).reverse_each.detect do |next_layer|
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
