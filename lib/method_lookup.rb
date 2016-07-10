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
        #next_method = Kernel.__get_next_method(current_class, self.class, method_selector, lookup_state.runtime_layer, current_owner)
        next_method = Kernel.__get_next_method(lookup_state)

        LOG.info("-P-> Calling #{next_method.name}")
        next_method.bind(target_object).call(*args, &block)
    end
end

module Kernel
    # Retrieves the next method (UnboundMethod) that should be called
    def self.__get_next_method(lookup_state)
        if lookup_state.current_layer == nil
            # check next superclass
            lookup_state.advance_current_class!
            lookup_state.top_of_composition_stack!
            __get_method_for(lookup_state)
        else
            # check next layer
            # TODO: how do we get the runtime_layer of current_layer???
            lookup_state.advance_runtime_layer!
            __get_method_for(lookup_state)
        end
    end

    def self.__get_method_for(lookup_state)
        if lookup_state.end_of_superclass_hierarchy?
            # Lookup failed
            return nil
        end

        if lookup_state.end_of_layer_stack?
            # base method
            mangled_selector = __original_selector(lookup_state.selector)
            if lookup_state.current_class.instance_methods.include?(mangled_selector)
                # found base method
                lookup_state.current_class.instance_method(mangled_selector)
            else
                # look for next partial method in superclass
                lookup_state.top_of_composition_stack!
                lookup_state.advance_current_class!
                __get_method_for(lookup_state)
            end
        else
            # look partial method/base method of current_class

            if lookup_state.end_of_runtime_layer_superclass_hierarchy?
                # exhausted search in superclass hierarchy of runtime_layer, progress to next layer
                lookup_state.advance_runtime_layer!
                # next_layer == nil indicates "check for base method next"
                __get_method_for(lookup_state)
            else
                mangled_selector = __partial_selector(lookup_state.selector, lookup_state.current_layer)
                if lookup_state.current_class.instance_methods.include?(mangled_selector)
                    # found partial method
                    lookup_state.current_class.instance_method(mangled_selector)
                else
                    # look for partial method in superclass of current layer, nil indicates "check next layer"
                    lookup_state.advance_current_layer!
                    __get_method_for(lookup_state)
                end
            end
        end
    end

    # Returns the layer underneath current_layer, or nil if there are no more layers
    def self.__get_next_layer(runtime_layer)
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

    def advance_current_class!
        @current_class = Kernel.__get_superclass(@current_class, @runtime_class)
    end

    def top_of_composition_stack!
        @current_layer = @runtime_layer = Kernel.__layer_stack.first
    end

    def advance_runtime_layer!
        @runtime_layer = @current_layer = Kernel.__get_next_layer(@runtime_layer)
    end

    def advance_current_layer!
        @current_layer = Kernel.__get_superclass(@current_layer, @runtime_layer)
    end

    def end_of_superclass_hierarchy?
        @current_class == nil
    end

    def end_of_runtime_layer_superclass_hierarchy?
        @current_layer == nil
    end

    def end_of_layer_stack?
        @runtime_layer == nil
    end
end
