# this class divides too long text, and also this class joins too small text.
class Voice::JapaneseTextReconstructor
  include Enumerable

  SEPARATOR = /[\s　。、]+/
  PAUSE_TEXT = '。'

  def initialize(texts, max_length)
    @texts = texts
    @max_length = max_length
  end

  def each
    # setup enumerable
    e = @texts.lazy

    # at first, split text into micro size.
    e = e.map do |text|
      chunk_text text
    end
    e = e.flat_map do |text|
      text
    end

    # and then slice into appropriate length.
    length = 0
    e = e.slice_before do |text|
      length += text.length
      if length > @max_length
        length = text.length
        true
      else
        false
      end
    end

    e = e.map do |text_array|
      text_array.join(PAUSE_TEXT) + PAUSE_TEXT
    end

    # finally, yields text which has appropriate length
    e.each do |text|
      yield text
    end
  end

  private
    def chunk_text(text)
      text.split(/[\s　。、]+/)
    end
end
