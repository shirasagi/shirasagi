class Voice::TextToSpeechFactory
  class << self
    def create(type, config = {})
      Voice::OpenJtalk.new(config)
    end
  end
end
