require "zanzou/version"

module Zanzou
  class ShadowNode < Object
    def initialize(orig_node, parent:, parent_key:)
      @orig_node, @parent, @parent_key = orig_node, parent, parent_key
      @modified = false
      @modifications = {}
    end

    def method_missing(name, *args)
      if name =~ /(.+)=/
        handle_setter($1.to_sym, args[0])
      else
        handle_getter(name.to_sym)
      end
    end

    private

    def handle_setter(key, value)
      @modifications[key] = value
      @modified = true

      # Mark ancestors to be modified
      parent = @parent
      while parent && !parent.instance_variable_get(:@modified)
        parent.instance_variable_set(:@modified, true)
        parent = parent.instance_variable_get(:@parent)
      end

      # Tell parent for the modification
      if @parent
        @parent.instance_variable_get(:@modifications)[@parent_key] = self
      end
    end

    def handle_getter(key)
      if @modifications.key?(key)
        @modifications[key]
      else
        ShadowNode.new(@orig_node.public_send(key), parent: self, parent_key: key)
      end
    end

    def self.finalize(shadow)
      orig_node = shadow.instance_variable_get(:@orig_node)
      modified = shadow.instance_variable_get(:@modified)
      modifications = shadow.instance_variable_get(:@modifications)
      modifications.transform_values!{|v|
        ShadowNode === v ? ShadowNode.finalize(v) : v
      }
      if modified
        hash = orig_node.to_h.merge(modifications)
        ret = orig_node.class.new(hash)
      else
        ret = orig_node
      end
      return ret
    end
  end

  def with_updates(&block)
    shadow = ShadowNode.new(self, parent: nil, parent_key: nil)
    block.call(shadow)
    return ShadowNode.finalize(shadow)
  end
end
