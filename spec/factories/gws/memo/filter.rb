FactoryGirl.define do

  factory :gws_memo_filter, class: Gws::Memo::Filter do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    from { "from-#{unique_id}" }
    subject { "subject-#{unique_id}" }
    action { 'trash' }
  end
end
