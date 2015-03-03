class Kana::Config
  def self.test_root
    prefix = "kana"
    timestamp = Time.now.strftime("%Y%m%d")
    tmp = ::File.join(Dir.tmpdir, "#{prefix}-#{timestamp}")
    ::Dir.mkdir(tmp) unless ::Dir.exists?(tmp)
    tmp
  end

  DEFAULT_ROOT = Rails.env.test? ? test_root : Rails.root.to_s

  cattr_reader(:default_values) do
    {
      disable: false,
      root: DEFAULT_ROOT,
      location: "/kana",
      mecab_indexer: "/usr/local/libexec/mecab/mecab-dict-index",
      mecab_dicdir: "/usr/local/lib/mecab/dic/ipadic"
    }
  end
end
