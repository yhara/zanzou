# require'ing this file improves Zanzou's performance, but it will
# break if any of these methods are redefined to be destructive.
require 'zanzou/whitelist'

module Zanzou
  module WhitelistArrayMethods
    NON_DESTRUCTIVE_ARRAY_METHODS = %i(
      & * + - <=> == [] at assoc bsearch bsearch_index clone dup 
      combination compact cycle difference dig each each_index empty?
      eql? fetch find_index index first flatten hash include? inspect
      to_s join last length size max min pack permutation pop product
      rassoc repeated_combination repeated_permutation reverse 
      reverse_each rindex rotate sample shuffle slice sort sum
      to_a to_ary to_h transpose union uniq values_at zip |
    ) +
      NON_DESTRUCTIVE_BASIC_OBJECT_METHODS +
      NON_DESTRUCTIVE_OBJECT_METHODS

    def method_missing(name, *args)
      if NON_DESTRUCTIVE_ARRAY_METHODS.include?(name)
        handle_non_destructive_method_call(name, args)
      else
        super
      end
    end
  end

  class ArrayShadow < ShadowNode
    prepend WhitelistArrayMethods
  end
end
