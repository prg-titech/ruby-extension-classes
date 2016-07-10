module Kernel
    def self.__partial_selector(selector, layer)
    	# TODO: should handle case where underscore is used in class name
        :"__#{selector}_partial_#{layer.to_s.gsub("::", "____")}"
    end

    def self.__original_selector(selector)
        :"__#{selector}_original"
    end

    def self.__selector_part_to_class_name(selector_part)
        selector_part.gsub("____", "::")
    end

    def self.__extract_selector_from_mangled_original(selector)
        selector[2...-9]
    end

    def self.__extract_selector_from_mangled_partial(selector)
    	splitted = selector.to_s[2..-1].split("_partial_")
    	# _partial_ might be part of the original selector
    	splitted.first(splitted.size - 1).join("_partial_")
    end

    def self.__get_class(class_name)
        Object.instance_eval(class_name)
    end
end
