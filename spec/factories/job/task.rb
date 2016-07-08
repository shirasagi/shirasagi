FactoryGirl.define do
  factory :job_model, class: Job::Task do
    transient do
      cur_site { cms_site }
    end

    site_id { cur_site.try(:id) }
    pool "default"
    class_name "Class"
    args [ "hello" ]
  end
end
