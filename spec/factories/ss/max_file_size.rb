FactoryBot.define do
  factory :ss_max_file_size, class: SS::MaxFileSize do
    name { unique_id }
    extensions { "*" }
    in_size_mb { 100 }
    state { "enabled" }
  end
end
