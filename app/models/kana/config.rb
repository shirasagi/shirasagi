class Kana::Config
  cattr_reader(:default_values) do
    {
      disable: false,
      location: "/kana",
      mecab_indexer: "/usr/local/libexec/mecab/mecab-dict-index",
      mecab_dicdir: "/usr/local/lib/mecab/dic/ipadic"
    }
  end
end
