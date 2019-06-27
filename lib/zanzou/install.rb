require 'zanzou'

class Object
  def with_updates(&block)
    Zanzou.with_updates(self, &block)
  end
end
