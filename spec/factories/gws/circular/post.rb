FactoryBot.define do
  factory :gws_circular_post, class: Gws::Circular::Post do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    text { "text-#{unique_id}" }

    trait :member_ids do
      #member_ids [3]
      member_ids { [gws_user.id] }
    end

    trait :due_date do
      due_date { Time.zone.tomorrow }
    end

    trait :gws_circular_posts do
      member_ids { [gws_user.id] }
      due_date { Time.zone.tomorrow }
    end

    trait :gws_circular_posts_item2 do
      member_ids { [gws_user.id] }
      due_date { Time.zone.tomorrow }
      seen { { gws_user.group_ids.first.to_s => Time.zone.now } }
    end

    trait :gws_circular_trashes do
      member_ids { [gws_user.id] }
      user_ids { [gws_user.id] }
      due_date { Time.zone.tomorrow }
      deleted { Time.zone.now }
    end

    trait :gws_circular_trashes_item2 do
      member_ids { [gws_user.id] }
      group_ids { gws_user.group_ids }
      due_date { Time.zone.tomorrow }
      deleted { Time.zone.now }
    end

    trait :gws_circular_trashes_item3 do
      member_ids { [gws_user.id] }
      user_ids { [gws_user.id] }
      due_date { Time.zone.tomorrow }
    end

    trait :gws_circular_trashes_item4 do
      member_ids { [gws_user.id] }
      due_date { Time.zone.tomorrow }
    end
  end
end
