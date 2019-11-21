FactoryBot.define do
  factory :resource_download_history, class: Opendata::ResourceDownloadHistory do
    cur_site { cms_site }
    downloaded_by { %w(single dataset bulk).sample }
  end
end
