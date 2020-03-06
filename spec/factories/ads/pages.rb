FactoryBot.define do
  factory :ads_banner, class: Ads::Banner, traits: [:cms_page] do
    filename { "dir/#{unique_id}" }
    route "ads/banner"
    link_url "http://example.jp/"
    file { SS::TmpDir.tmp_ss_file(site: cur_site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", basename: 'logo.png') }
  end
end
