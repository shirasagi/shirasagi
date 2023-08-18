module SS::Translation
  def model_name
    ActiveModel::Name.new(self)
  end
end
