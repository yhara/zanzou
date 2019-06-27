module Zanzou
  NON_DESTRUCTIVE_BASIC_OBJECT_METHODS = %i(
    ! != == __id__ equal?
  )

  NON_DESTRUCTIVE_OBJECT_METHODS = %i(
    ~ <=> == === =~ class clone dup display enum_for to_enum eql? equal? 
    frozen? hash inspect instance_of? instance_variable_defined? 
    instance_variable_get instance_variables is_a? kind_of? itself 
    method methods nil? object_id private_methods protected_methods 
    public_method public_methods respond_to? singleton_class 
    singleton_method singleton_methods tainted? tap then yield_self
    to_a to_ary to_hash to_int to_io to_proc to_regexp to_s to_str
    untrusted?
  )
end
