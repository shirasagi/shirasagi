FactoryGirl.define do
  factory :job_model, class: Job::Task do
    transient do
      site nil
      user nil
    end

    site_id { site.present? ? site.id : nil }
    user_id { user.present? ? user.id : nil }
    pool "default"
    class_name "Class"
    args [ "hello" ]
  end
end
