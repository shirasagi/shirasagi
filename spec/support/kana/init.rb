def can_test_mecab_spec?
  # In Travis Ci dictionares_controller#build failed because of there is no MeCab installed.
  # So, before test, check whether we can do MeCab specific tests.
  return false if SS.config.kana.disable
  unless ::File.exists?(SS.config.kana.mecab_indexer)
    puts("[MeCab Spec] not found: #{SS.config.kana.mecab_indexer}")
    return false
  end
  unless ::File.exists?(SS.config.kana.mecab_dicdir)
    puts("[MeCab Spec] not found: #{SS.config.kana.mecab_dicdir}")
    return false
  end
  true
end
