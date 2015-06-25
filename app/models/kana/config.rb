class Kana::Config
  class << self
    def root
      File.join(Rails.root, "private", "files", "kana_dictionaries")
    end
  end
end
