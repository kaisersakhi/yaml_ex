class PartialObject
  def initialize(partial_text:, key:)
    self.partial_text = partial_text
    self.key = key
  end
  attr_accessor :partial_text, :key
end