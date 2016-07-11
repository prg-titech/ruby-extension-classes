# Extension Classes for Ruby
This is a prototypical implementation of *Extension Classes* for Ruby. Extension Classes allow classes to define class extensions (i.e., method additions and method refinements) for other classes. Changes are visible only in a certain scope and not global. Visibility is determined by the class nesting hierarchy, the superclass hierarchy, and the classes being extended by a class.

This implementation uses metaprogramming and low-level Rubygems based on C extensions (`binding_of_caller`, `debug_inspector`). It works only with Ruby 2.3.0 (possibly newer versions). Performance is explicitly not a goal at this point of time. The biggest slowdown occurs due to the reimplementation of the method lookup in Ruby code.

