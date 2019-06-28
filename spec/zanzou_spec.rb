require 'spec_helper'
require 'zanzou'

class HashLike
  include Zanzou

  class HashLikeShadow < Zanzou::HashShadow
    def self.merge(orig_hashlike, modifications)
      HashLike.new(orig_hashlike.to_h.merge(modifications))
    end

    def method_missing(name, *args)
      if name =~ /(.+)=/
        handle_setter($1.to_sym, args[0])
      else
        handle_getter(name)
      end
    end
  end

  def zanzou_class
    HashLikeShadow
  end
  
  def initialize(hash={})
    @hash = hash
  end

  def respond_to?(key)
    key == :zanzou_class || @hash.key?(key)
  end

  def method_missing(name, *args)
    if name =~ /(.*)=/
      @hash[$1] = args[0]
    else
      @hash.fetch(name.to_sym)
    end
  end

  def to_h
    @hash
  end
end

describe "Zanzou#with_updates" do
  context "HashLike" do
    it "should not change the original" do
      orig = HashLike.new(a: 1, b: HashLike.new(c: 3, d: 4))
      new_obj = orig.with_updates{|o|
        o.b.d = 5
      }

      expect(orig.b.d).to eq(4)
      expect(new_obj.b.d).to eq(5)
    end

    it "should return the object if no change is made" do
      orig = HashLike.new
      new_obj = orig.with_updates{}

      expect(new_obj).to be(orig)
    end

    it "should not duplicate unchanged objects" do
      orig = HashLike.new(a: 1, b: [])
      new_obj = orig.with_updates{|o| o.a = 2}

      expect(new_obj.b).to be(orig.b)
    end
  end

  context "Array" do
    it "destructive method does not modify the original" do
      orig = [1,2,3]
      new_obj = Zanzou.with_updates(orig){|o| o.pop}

      expect(orig).to eq([1,2,3])
      expect(new_obj).to eq([1,2])
    end

    it "#[]=" do
      orig = [1,[2,3],4]
      new_obj = Zanzou.with_updates(orig){|o| o[1][1] = 99}

      expect(orig).to eq([1,[2,3],4])
      expect(new_obj).to eq([1,[2,99],4])
    end

    it "should apply modification of children before index changes" do
      orig = [1, 2, [3, 4]]
      new_obj = Zanzou.with_updates(orig){|o|
        o[2][1] = 99
        o.shift
      }

      expect(orig).to eq([1,2,[3,4]])
      expect(new_obj).to eq([2,[3,99]])
    end
  end

  context "Hash" do
    it "destructive method does not modify the original" do
      orig = HashLike.new(a: 1, b: {c: 1})
      new_obj = orig.with_updates{|o| o.b.shift}

      expect(orig.b).to eq({c: 1})
      expect(new_obj.b).to eq({})
    end

    it "#[]=" do
      orig = HashLike.new(a: 1, b: {c: 1})
      new_obj = orig.with_updates{|o| o.b[:c] = 99}

      expect(orig.b).to eq({c: 1})
      expect(new_obj.b).to eq({c: 99})
    end
  end

  context "String" do
    it "destructive method does not modify the original" do
      orig = HashLike.new(s: "hi")
      new_obj = orig.with_updates{|o| o.s.upcase!}

      expect(orig.s).to eq("hi")
      expect(new_obj.s).to eq("HI")
    end
  end
end

# TODO: HashWithIndifferentAccess
