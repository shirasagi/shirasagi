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

RSpec.configuration.before(:suite) do
  prefix = "kana"
  timestamp = Time.zone.now.strftime("%Y%m%d")
  tmp = ::File.join(Dir.tmpdir, "#{prefix}-#{timestamp}")
  ::Dir.mkdir(tmp) unless ::Dir.exists?(tmp)

  SS.config.kana
  SS.config.replace_value_at(:kana, :root, tmp)
end

RSpec.configuration.after(:suite) do
  #::FileUtils.rm_rf SS.config.kana.root if ::Dir.exists?(SS.config.kana.root)
  ::FileUtils.rm_rf Kana::Config.root if ::Dir.exists?(Kana::Config.root)
end
