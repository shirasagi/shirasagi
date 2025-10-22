FactoryBot.define do
  factory :cms_unfavorable_word, class: Cms::UnfavorableWord do
    cur_site { cms_site }
    name { unique_id.to_s }
    body { ::File.read("#{Rails.root}/db/seeds/cms/unfavorable_word/basic.txt") }
    state { "enabled" }
  end
end
