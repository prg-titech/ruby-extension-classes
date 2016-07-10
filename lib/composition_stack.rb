module Kernel
    @@__layer_stack = []

    def self.__layer_stack
        # top of stack is first element
        @@__layer_stack
    end

    def self.__activate_layer(layer)
        if !__layer_stack.include?(layer)
            LOG.info("Activating layer: #{layer}")
            # push to front
            __layer_stack.unshift(layer)
        else
        	LOG.warn("TODO: layer already activated, implement layer shuffling")
        end
    end

    def self.__with_layer(layer, &block)
        original_layer_stack = @@__layer_stack.clone

        classes_to_activate = Kernel.__activation_rule_get_all_classes_for(layer)
        classes_to_activate.each do |layer|
        	__activate_layer(layer)
        end

        LOG.info("Layer stack: #{__layer_stack}")
        result = yield
        @@__layer_stack = original_layer_stack
        LOG.info("Layer stack: #{__layer_stack}")
        result
    end
end
