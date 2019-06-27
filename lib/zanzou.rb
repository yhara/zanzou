require "zanzou/version"

module Zanzou
  class ShadowNode
    IMMUTABLE_CLASSES = [
      TrueClass, FalseClass, NilClass,
      Symbol, Numeric
    ]

    def self.create(orig_obj, parent:, parent_key:)
      case orig_obj
      when Array
        ArrayShadow.new(orig_obj, parent: parent, parent_key: parent_key)
      when Hash
        HashShadow.new(orig_obj, parent: parent, parent_key: parent_key)
      else
        if orig_obj.frozen? || IMMUTABLE_CLASSES.include?(orig_obj.class)
          orig_obj
        elsif orig_obj.respond_to?(:zanzou_class)
          orig_obj.zanzou_class.new(orig_obj, parent: parent, parent_key: parent_key)
        else
          AnyObjectShadow.new(orig_obj, parent: parent, parent_key: parent_key)
        end
      end
    end

    def self.finalize(shadow)
      orig_obj      = shadow.instance_variable_get(:@orig_obj)
      modified      = shadow.instance_variable_get(:@modified)
      new_obj       = shadow.instance_variable_get(:@new_obj)
      modifications = shadow.instance_variable_get(:@modifications)
      modifications.transform_values!{|v|
        ShadowNode === v ? ShadowNode.finalize(v) : v
      }

      #pp cls: shadow.class.name, orig_obj: orig_obj, modified: modified, modifications: modifications, new_obj: new_obj
      if modified
        if new_obj
          if modifications.empty?
            ret = new_obj
          else
            ret = shadow.class.merge(new_obj, modifications)
          end
        else
          if modifications.empty?
            ret = orig_obj
          else
            ret = shadow.class.merge(orig_obj, modifications)
          end
        end
      else
        ret = orig_obj
      end
      #pp ret: ret
      return ret
    end

    def initialize(orig_obj, parent:, parent_key:)
      @orig_obj, @parent, @parent_key = orig_obj, parent, parent_key
      @modified = false
      @modifications = {}
      @new_obj = nil
    end

    private

    def handle_destructive_method_call(name, args)
      modified!
      @new_obj = @orig_obj.dup
      return @new_obj.public_send(name, *args)
    end

    def handle_non_destructive_method_call(name, args)
      return (@new_obj || @orig_obj).public_send(name, *args)
    end

    def modified!
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
  end

  class HashShadow < ShadowNode
    def self.merge(orig_hash, modifications)
      orig_hash.merge(modifications)
    end

    def method_missing(name, *args)
      case name
      when :[]=
        handle_setter(args[0], args[1])
      when :[]
        handle_getter(args[0])
      else
        handle_destructive_method_call(name, args)
      end
    end

    private

    def handle_setter(key, value)
      modified!
      @modifications[key] = value
      return value
    end

    def handle_getter(key)
      if @modifications.key?(key)
        return @modifications[key]
      else
        return ShadowNode.create(@orig_obj.public_send(key), parent: self, parent_key: key)
      end
    end
  end

  class ArrayShadow < ShadowNode
    def self.merge(orig_ary, modifications)
      ret = orig_ary.dup
      modifications.each{|k, v| ret[k] = v}
      ret
    end

    def initialize(*args)
      super
      @children = {}
    end

    def method_missing(name, *args)
      case name
      when :[]=
        handle_setter(args[0], args[1])
      when :[]
        handle_getter(args[0])
      else
        handle_destructive_method_call(name, args)
      end
    end

    private

    def handle_setter(idx, value)
      modified!
      @new_obj = @orig_obj.dup
      @new_obj[idx] = value
      return value
    end

    def handle_getter(idx)
      if @new_obj
        return @new_obj[idx]
      else
        return ShadowNode.create(@orig_obj[idx], parent: self, parent_key: idx)
      end
    end

    def handle_destructive_method_call(name, args)
      modified!
      @new_obj = @orig_obj.dup
      return @new_obj.public_send(name, *args)
    end
  end

  # Shadow for any Ruby objects (except container objects, which needs 
  # special Shadow class to handle parent-child relationship).
  # We know nothing about the class, so assume all methods are
  # destructive (pessimistic)
  class AnyObjectShadow < ShadowNode
    def method_missing(name, *args)
      return handle_destructive_method_call(name, args)
    end
  end

  def with_updates(&block)
    Zanzou.with_updates(self, &block)
  end

  def self.with_updates(obj, &block)
    shadow = ShadowNode.create(obj, parent: nil, parent_key: nil)
    block.call(shadow)
    return ShadowNode.finalize(shadow)
  end
end
