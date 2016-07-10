def extend(class_to_extend):
    def decorator(extending_class):
        class_to_extend.__dict__.update(extending_class.__dict__)
        return class_to_extend
    return decorator

class A:
	def m1(self):
		print(123)

a = A()

@extend(A)
class SomeClassThatAlreadyExists:
    def some_method(self, foo):
        print(foo)

a.m1()
a.some_method(456)

