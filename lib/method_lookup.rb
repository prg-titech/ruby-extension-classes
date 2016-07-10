require "binding_of_caller"
require "debug_inspector"

class Object
    def proceed(*args, &block)
        # TODO: this code works only for instance methods at the moment

        current_method_selector = binding.of_caller(1).eval("__callee__")
        is_base = current_method_selector.to_s.end_with?("_original")

        target_object = target_class = binding.of_caller(1).eval("self")
        if !target_class.is_a?(Module)
            target_class = target_class.class
        end

        # Invoke next partial method (or base method)
        LOG.info("Current method selector: #{current_method_selector}")

        # Determine the layer which contains this method
        current_owner = nil
        if not is_base
            current_owner_str = current_method_selector.to_s.split("_partial_").last
            current_owner = Kernel.__get_class(Kernel.__selector_part_to_class_name(current_owner_str))
        end

        # Retrieve the exact class to which this method belongs (not polymorphic type)
        current_class = nil
        RubyVM::DebugInspector.open do |i| 
            current_class = i.frame_class(2)
        end

        # Retrieve the original, unmangled selector
        method_selector = nil
        if is_base
            method_selector = Kernel.__extract_selector_from_mangled_original(current_method_selector)
        else
            method_selector = Kernel.__extract_selector_from_mangled_partial(current_method_selector)
        end

        # Method lookup
        next_method = Kernel.__get_next_method(current_class, self.class, method_selector, current_owner)

        LOG.info("-P-> Calling #{next_method.name}")
        next_method.bind(target_object).call(*args, &block)
    end
end

module Kernel
    # Retrieves the next method (UnboundMethod) that should be called
    def self.__get_next_method(current_class, runtime_class, selector, current_layer = nil)
        if current_layer == nil
            # check next superclass
            __get_method_for(__get_superclass(current_class, runtime_class), runtime_class, selector, __layer_stack.first)
        else
            # check next layer
            __get_method_for(current_class, runtime_class, selector, __get_next_layer(current_layer))
        end
    end

    def self.__get_method_for(current_class, runtime_class, selector, current_layer = nil)
        if current_class == nil
            # Lookup failed
            return nil
        end

        if current_layer == nil
            # base method
            mangled_selector = __original_selector(selector)
            if current_class.instance_methods.include?(mangled_selector)
                # found base method
                current_class.instance_method(mangled_selector)
            else
                # look for next partial method in superclass
                next_layer = __layer_stack.first
                next_class = __get_superclass(current_class, runtime_class)
                # next_layer == nil indicates "check for base method next"
                __get_method_for(next_class, runtime_class, selector, next_layer)
            end
        else
            # look partial method/base method of current_class
            mangled_selector = __partial_selector(selector, current_layer)
            if current_class.instance_methods.include?(mangled_selector)
                # found partial method
                current_class.instance_method(mangled_selector)
            else
                # look for next partial method
                next_layer = __get_next_layer(current_layer)
                # next_layer == nil indicates "check for base method next"
                __get_method_for(current_class, runtime_class, selector, next_layer)
            end
        end
    end

    # Returns the layer underneath current_layer, or nil if there are no more layers
    def self.__get_next_layer(current_layer)
        __layer_stack[__layer_stack.find_index(current_layer) + 1]
    end

    # Returns the next superclass/supermodule of klass in the hierarchy of runtime_class
    def self.__get_superclass(klass, runtime_class)
        # Don't use "superclass" method to account for modules
        superclasses = runtime_class.ancestors - [BasicObject]
        superclasses[superclasses.find_index(klass) + 1]
    end
end

