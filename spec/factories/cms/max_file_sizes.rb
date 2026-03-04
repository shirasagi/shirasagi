FactoryBot.define do
  factory :cms_max_file_size, class: Cms::MaxFileSize do
    name { "name-#{unique_id}" }
    extensions { Array.new(2) { "ext-#{unique_id}" } }
    size { rand(1..10) * 1_024 * 1_024 }
    order { rand(10..20) }
    state { "enabled" }
  end
end
