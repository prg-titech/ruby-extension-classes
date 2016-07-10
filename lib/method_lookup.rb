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
        lookup_state = nil
        RubyVM::DebugInspector.open do |i| 
            current_class = i.frame_class(2)

            # Walk stack to find stack frame where the wrapper is defined
            next_frame_index = 2
            while true do 
                begin
                    next_frame_index += 1
                    frame_binding = i.frame_binding(next_frame_index)

                    if frame_binding != nil and i.frame_class(next_frame_index) == self.class
                        if frame_binding.local_variables.include?(:__lookup_state)
                            lookup_state = frame_binding.local_variable_get(:__lookup_state)
                            break
                        end
                    end
                rescue ArgumentError => e
                    raise "Unable to find wrapper method frame"
                end
            end
        end

        if lookup_state == nil
            raise "Unable to find wrapper method frame"
        end

        # Retrieve the original, unmangled selector
        method_selector = lookup_state.selector

        # Method lookup
        next_method = Kernel.__get_next_method(current_class, self.class, method_selector, lookup_state.runtime_layer, current_owner)

        LOG.info("-P-> Calling #{next_method.name}")
        next_method.bind(target_object).call(*args, &block)
    end
end

module Kernel
    # Retrieves the next method (UnboundMethod) that should be called
    def self.__get_next_method(current_class, runtime_class, selector, runtime_layer, current_layer = nil)
        if current_layer == nil
            # check next superclass
            __get_method_for(__get_superclass(current_class, runtime_class), runtime_class, selector, __layer_stack.first)
        else
            # check next layer
            # TODO: how do we get the runtime_layer of current_layer???
            __get_method_for(current_class, runtime_class, selector, __get_next_layer(current_layer))
        end
    end

    # current_class: Lookup class in receiver's class hierarchy
    # runtime_class: Receiver's runtime class
    # current_layer: Current lookup layer (which layer are we attempting to call a method from)
    # runtime_layer: Layer class (most specific subtype)
    def self.__get_method_for(current_class, runtime_class, selector, runtime_layer = nil, current_layer = runtime_layer)
        puts " ____ GET METHOD FOR (current_class: #{current_class}, runtime_class: #{runtime_class}, selector: #{selector}, runtime_layer: #{runtime_layer}"
        if current_class == nil
            # Lookup failed
            return nil
        end

        if runtime_layer == nil
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

            if current_layer == nil
                # exhausted search in superclass hierarchy of runtime_layer, progress to next layer
                next_layer = __get_next_layer(runtime_layer)
                # next_layer == nil indicates "check for base method next"
                __get_method_for(current_class, runtime_class, selector, next_layer)
            else
                mangled_selector = __partial_selector(selector, current_layer)
                if current_class.instance_methods.include?(mangled_selector)
                    # found partial method
                    current_class.instance_method(mangled_selector)
                else
                    # look for partial method in superclass of current layer, nil indicates "check next layer"
                    layer_superclass = __get_superclass(current_layer, runtime_layer)
                    __get_method_for(current_class, runtime_class, selector, runtime_layer, layer_superclass)
                end
            end
        end
    end

    # Returns the layer underneath current_layer, or nil if there are no more layers
    def self.__get_next_layer(runtime_layer)
        puts "RRR: #{runtime_layer}"
        __layer_stack[__layer_stack.find_index(runtime_layer) + 1]
    end

    # Returns the next superclass/supermodule of klass in the hierarchy of runtime_class
    def self.__get_superclass(klass, runtime_class)
        # Don't use "superclass" method to account for modules
        superclasses = runtime_class.ancestors - [BasicObject]
        superclasses[superclasses.find_index(klass) + 1]
    end
end

class LookupState
    def initialize(current_class:, runtime_class:, selector:, runtime_layer:, current_layer: runtime_layer)
        @current_class = current_class
        @runtime_class = runtime_class
        @current_layer = current_layer
        @runtime_layer = runtime_layer
        @selector = selector
    end

    attr_accessor :runtime_class
    attr_accessor :runtime_layer
    attr_accessor :current_class
    attr_accessor :current_layer
    attr_accessor :selector
end
