module Kernel
    def self.__partial_selector(selector, layer)
    	# TODO: should handle case where underscore is used in class name
        :"__#{selector}_partial_#{layer.to_s.gsub("::", "_")}"
    end

    def self.__original_selector(selector)
        :"__#{selector}_original"
    end

    def self.__extract_selector_from_mangled_partial(selector)
    	splitted = selector.to_s[2..-1].split("_partial_")
    	# _partial_ might be part of the original selector
    	splitted.first(splitted.size - 1).join("_partial_")
    end
end
