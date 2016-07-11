require "binding_of_caller"
require "debug_inspector"

class Object
    # Invoke next partial method (or base method)
    def proceed(*args, &block)
        # TODO: this code works only for instance methods at the moment
        target_object = target_class = binding.of_caller(1).eval("self")

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
        next_method = lookup_state.get_method_for_next_state

        LOG.info("-P-> Calling #{next_method.name}")
        next_method.bind(target_object).call(*args, &block)
    end
end

# Stored the state of the current lookup. Will be reused when calling "proceed"
# to determine the next method to be invoked.
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

    # Returns the layer underneath current_layer, or nil if there are no more layers
    def self.__get_next_layer(runtime_layer)
        Kernel.__layer_stack[Kernel.__layer_stack.find_index(runtime_layer) + 1]
    end

    # Returns the next superclass/supermodule of klass in the hierarchy of runtime_class
    def self.__get_superclass(klass, runtime_class)
        # Don't use "superclass" method to account for modules
        superclasses = runtime_class.ancestors - [BasicObject]
        superclasses[superclasses.find_index(klass) + 1]
    end

    def advance_current_class!
        @current_class = LookupState.__get_superclass(@current_class, @runtime_class)
    end

    def top_of_composition_stack!
        @current_layer = @runtime_layer = Kernel.__layer_stack.first
    end

    def advance_runtime_layer!
        @runtime_layer = @current_layer = LookupState.__get_next_layer(@runtime_layer)
    end

    def advance_current_layer!
        @current_layer = LookupState.__get_superclass(@current_layer, @runtime_layer)
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

    # Get method for current state. Does not advance the state if necessary (only if the lookup would otherwise be unsuccessful; i.e., determines current method to be called).
    def get_method_for_this_state
        if end_of_superclass_hierarchy?
            # Lookup failed
            return nil
        end

        if end_of_layer_stack?
            # base method
            mangled_selector = Kernel.__original_selector(selector)
            if current_class.instance_methods(false).include?(mangled_selector)
                # found base method
                current_class.instance_method(mangled_selector)
            else
                # look for next partial method in superclass
                top_of_composition_stack!
                advance_current_class!
                get_method_for_this_state
            end
        else
            # look partial method/base method of current_class

            if end_of_runtime_layer_superclass_hierarchy?
                # exhausted search in superclass hierarchy of runtime_layer, progress to next layer
                advance_runtime_layer!
                # next_layer == nil indicates "check for base method next"
                get_method_for_this_state
            else
                mangled_selector = Kernel.__partial_selector(selector, current_layer)
                if current_class.instance_methods(false).include?(mangled_selector)
                    # found partial method
                    current_class.instance_method(mangled_selector)
                else
                    # look for partial method in superclass of current layer, nil indicates "check next layer"
                    advance_current_layer!
                    get_method_for_this_state
                end
            end
        end
    end

    # Advances the state and performs a lookup (i.e., determines next method to be called).
    def get_method_for_next_state
        if end_of_layer_stack?
            # check next superclass
            top_of_composition_stack!
            advance_current_class!
            get_method_for_this_state
        else
            if end_of_runtime_layer_superclass_hierarchy?
                advance_runtime_layer!
                get_method_for_this_state
            else
                advance_current_layer!
                get_method_for_this_state
            end
        end
    end
end
