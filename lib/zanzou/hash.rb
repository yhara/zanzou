# require'ing this file improves Zanzou's performance, but it will
# break if any of these methods are redefined to be destructive.
require 'zanzou/whitelist'

module Zanzou
  module WhitelistHashMethods
    NON_DESTRUCTIVE_HASH_METHODS = %i(
      < <= == === eql? > >= [] assoc clone dup compact compare_by_identity?
      default default_proc dig each each_pair each_key each_value empty?
      equal? fetch fetch_values filter select flatten has_key? include?
      key? member? has_value? value? hash index key inspect to_s invert
      keys length size merge rassoc reject slice sort to_a to_h to_hash
      to_proc transform_keys transform_values values values_at
    ) +
      NON_DESTRUCTIVE_BASIC_OBJECT_METHODS +
      NON_DESTRUCTIVE_OBJECT_METHODS

    def method_missing(name, *args)
      if NON_DESTRUCTIVE_METHODS.include?(name)
        handle_non_destructive_method_call(name, args)
      else
        super
      end
    end
  end

  class HashShadow < ShadowNode
    prepend WhitelistHashMethods
  end
end

