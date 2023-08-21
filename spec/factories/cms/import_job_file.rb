FactoryBot.define do
  factory :cms_import_job_file, class: Cms::ImportJobFile do
    cur_site { cms_site }
    cur_user { cms_user }
  end
end
