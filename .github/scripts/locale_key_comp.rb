class LocaleKeyComp
  class Locale
    include ActiveModel::Model

    attr_accessor :file_path, :locale, :parent_keys

    def keys
      locale.keys
    end

    def slice(key)
      self.class.new(file_path: file_path, locale: locale[key], parent_keys: parent_keys + [key])
    end

    def hash_value?(key)
      locale[key].is_a?(Hash)
    end

    def relative_file_path
      file_path.sub("#{Rails.root}/", "")
    end
  end

  def call
    each_locale_pair do |ja_locale, en_locale|
      # puts "ja keys" + ja_locale.keys.join(",")
      # puts "en keys" + en_locale.keys.join(",")
      compare(ja_locale, en_locale)
    end
  end

  private

  def each_locale_pair
    ::Dir.glob(Rails.root.join("config/**/en.yml")).sort.each do |en_path|
      next unless ::File.exist?(en_path)

      ja_path = en_path.sub("en.yml", "ja.yml")
      next unless ::File.exist?(ja_path)

      ja = YAML.load_file(ja_path)
      en = YAML.load_file(en_path)
      ja_locale = Locale.new(file_path: ja_path, locale: ja["ja"], parent_keys: ["ja"])
      en_locale = Locale.new(file_path: en_path, locale: en["en"], parent_keys: ["en"])

      yield ja_locale, en_locale
    end
  end

  def compare(ja_locale, en_locale)
    (ja_locale.keys - en_locale.keys).tap do |keys_only_in_ja|
      if keys_only_in_ja.present?
        report_diff keys_only_in_ja, ja_locale, en_locale, " は日本語ロケールにのみ存在します。"
      end
    end
    (en_locale.keys - ja_locale.keys).tap do |keys_only_in_en|
      if keys_only_in_en.present?
        report_diff keys_only_in_en, en_locale, ja_locale, " は英語ロケールにのみ存在します。"
      end
    end

    common_keys = ja_locale.keys & en_locale.keys
    common_keys.each do |key|
      if ja_locale.hash_value?(key)
        compare ja_locale.slice(key), en_locale.slice(key)
      end
    end
  end

  def report_diff(diff_keys, lhs_locale, _rsh_locale, message)
    diff_keys.each do |key|
      lineno, position = find_location(key, lhs_locale)
      messages = [ lhs_locale.relative_file_path ]
      if lineno
        messages << lineno
        if position
          messages << position
        end
      end
      messages << " #{lhs_locale.parent_keys.join(".")}.#{key}#{message}"
      puts messages.join(":")
    end
  end

  def find_location(key, locale)
    lineno = 1
    last_line = nil
    last_key = nil
    found = nil
    keys = locale.parent_keys + [ key ]
    ::File.foreach(locale.file_path) do |line|
      if line.match?(/^\s*#{::Regexp.escape(keys.first)}:/)
        last_line = line
        last_key = keys.shift
        if keys.blank?
          found = lineno
          break
        end
      end
      lineno += 1
    end

    if found
      pos = (last_line =~ /#{::Regexp.escape(last_key)}:/)
    end
    [ found, pos ]
  end
end

LocaleKeyComp.new.call
