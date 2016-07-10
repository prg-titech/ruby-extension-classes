

class AA
    def bar
        puts "SUPER INVOKED!"
    end
end

class Y
    class Z < AA
        def bar
            puts "ORIGINAL BAR"
            proceed
            #super
            3
        end
    end
end

class X
    def test_x
        Y::Z.new.bar
    end

    partial

    class Y::Z
        def bar
            puts "Y::Z.bar"
            proceed + 2
        end

        def self.qux
            puts "Y::Z.qux"
        end
    end
end

class X
    # TODO: need to reset to public automatically
    public

    class Y::Z
        def foo
            puts "No partial"
        end
    end
end

#puts X.new.test_x




# SINGLE LEVEL NESTING TEST

class T_A
    def foo
        puts 456
    end
end

class T_B

    def bla
        T_A.new.foo
    end

    partial

    class ::T_A
        def foo
            puts 123
            proceed
        end
    end
end

puts T_B::T_A
puts T_A
puts T_B::T_A == T_A
T_B.new.bla

