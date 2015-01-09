FactoryGirl.define do
  path1 = SecureRandom.hex(13)
  path2 = SecureRandom.hex(13)

  factory :voice_voice_file, class: Voice::VoiceFile do
    site_id { cms_site.id }
    path "#{path1}"
    url { "http://#{cms_site.domain}/#{path1}" }
    last_modified Time.now
  end

  factory :voice_voice_file_with_error, class: Voice::VoiceFile do
    site_id { cms_site.id }
    path "#{path2}"
    url { "http://#{cms_site.domain}/#{path2}" }
    last_modified Time.now
    error "failed to create"
  end
end
