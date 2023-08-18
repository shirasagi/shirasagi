FactoryBot.define do
  factory :opendata_license, class: Opendata::License do
    name { unique_id }
    cur_site { cms_site }
    file { SS::TmpDir.tmp_ss_file(site: cur_site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
  end
end
