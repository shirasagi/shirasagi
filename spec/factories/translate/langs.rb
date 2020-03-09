FactoryBot.define do
  trait :translate_lang do
    cur_site { cms_site }
  end

  factory :translate_lang_ja, class: Translate::Lang, traits: [:translate_lang] do
    name "日本語"
    code "ja"
    microsoft_translator_text_code "ja"
    google_translation_code "ja"
    mock_code "ja"
    accept_languages %w(ja)
  end

  factory :translate_lang_en, class: Translate::Lang, traits: [:translate_lang] do
    name "英語"
    code "en"
    microsoft_translator_text_code "en"
    google_translation_code "en"
    mock_code "en"
    accept_languages %w(en)
  end


  factory :translate_lang_ko, class: Translate::Lang, traits: [:translate_lang] do
    name "韓国語"
    code "ko"
    microsoft_translator_text_code "ko"
    google_translation_code "ko"
    mock_code "ko"
    accept_languages %w(ko)
  end

  factory :translate_lang_zh_cn, class: Translate::Lang, traits: [:translate_lang] do
    name "中国語（簡体）"
    code "zh-CN"
    microsoft_translator_text_code "zh-Hans"
    google_translation_code "zh-CN"
    mock_code "zh-CN"
    accept_languages %w(zh zh-CN)
  end

  factory :translate_lang_zh_tw, class: Translate::Lang, traits: [:translate_lang] do
    name "中国語（繁体）"
    code "zh-TW"
    microsoft_translator_text_code "zh-Hant"
    google_translation_code "zh-TW"
    mock_code "zh-TW"
    accept_languages %w(zh-TW)
  end
end
