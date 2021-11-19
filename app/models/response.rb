class Response < String
  attr_accessor :text

  def initialize(text = '')
    @text = text
  end

end
