FactoryGirl.define do
  path1 = rand(0x100000000).to_s(36)
  path2 = rand(0x100000000).to_s(36)
  page_identity1 = rand(0x100000000).to_s(36)
  page_identity2 = rand(0x100000000).to_s(36)

  factory :voice_voice_file, class: Voice::VoiceFile do
    site_id { cms_site.id }
    path "#{path1}"
    url { "http://#{cms_site.domain}/#{path1}" }
    page_identity page_identity1
  end

  factory :voice_voice_file_with_error, class: Voice::VoiceFile do
    site_id { cms_site.id }
    path "#{path2}"
    url { "http://#{cms_site.domain}/#{path2}" }
    page_identity page_identity2
    error "failed to create"
  end
end
