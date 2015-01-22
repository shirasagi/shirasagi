class Kana::CsvEnumerable
  include Enumerable

  FIELD_SEPARATORS = %w(, 、 ，)
  KATAKANA_REGEX = /^[ァ-ンーヴ]+$/

  def initialize(model, separators = FIELD_SEPARATORS)
    @model = model
    @separator_regex = /\s*(#{separators.join("|")})\s*/
  end

  def each
    return if @model.body.blank?

    e = setup_enumerable

    # remove comments
    e = e.map do |line|
      preprocess line
    end

    # remove blanks
    e = e.select do |line|
      line.present?
    end

    # split and normalize
    e = e.map do |line, line_no|
      word, yomi = split_and_normalize line
      [ line, line_no, word, yomi ]
    end

    # filter out invalid csv
    e = e.select do |line, line_no, word, yomi|
      validate_csv_item line, line_no, word, yomi
    end

    # yield
    e.each do |line, line_no, word, yomi|
      yield word, yomi
    end
  end

  private
    def setup_enumerable
      @model.body.each_line.with_index(1).lazy
    end

    def preprocess(line)
      line = line.to_s.gsub(/#.*/, "")
      line.strip
    end

    def split_and_normalize(line)
      word, delim, yomi = line.split(@separator_regex)
      word ||= ''
      yomi ||= ''
      [ word.strip, yomi.strip.tr("ぁ-ん", "ァ-ン") ]
    end

    def validate_csv_item(line, line_no, word, yomi)
      if word.blank? || yomi.blank?
        @model.errors.add :base, :malformed_kana_dictionary, line: line, no: line_no
        return false
      end

      unless katakana?(yomi)
        @model.errors.add :base, :malformed_kana_dictionary, line: line, no: line_no
        return false
      end

      true
    end

    def katakana?(yomi)
      KATAKANA_REGEX =~ yomi
    end
end
