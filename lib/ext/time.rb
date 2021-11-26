class Time
  def floor(sec=1)
    Time.at(self - (self.to_i % sec))
  end
end
