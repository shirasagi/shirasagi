class Voice::TextToSpeechFactory
  class << self
    public
      def create(type, config = {})
        Voice::OpenJtalk.new(config)
      end
  end
end
