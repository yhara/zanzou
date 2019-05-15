require 'zanzou'

class HashLike
  include Zanzou
  
  def initialize(hash={})
    @hash = hash
  end

  def respond_to?(key)
    @hash.key?(key)
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

# TODO: Array
# TODO: HashWithIndifferentAccess
