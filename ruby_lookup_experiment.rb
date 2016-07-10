class A
  class B

  end

  FOO = 123
end

class C
  #FOO = 456

  class D < A::B
    def bar
      puts FOO
    end
  end
end

C::D.new.bar
