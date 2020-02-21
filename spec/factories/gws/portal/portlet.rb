FactoryBot.define do
  trait :gws_portal_portlet_base do
    cur_site { gws_site }
    cur_user { gws_user }

    name { "name-#{unique_id}" }
    limit 1
  end

  trait :gws_portal_schedule_portlet do
    portlet_model "schedule"
  end

  trait :gws_portal_ad_portlet do
    portlet_model "ad"
    ad_width { rand(300..400) }
    ad_speed { rand(10..30) }
    ad_pause { rand(60..90) }

    after(:build) do |portlet, evaluator|
      name = "#{unique_id}.png"
      file = SS::TempFile.create_empty!(name: name, filename: name, content_type: 'image/png') do |file|
        ::FileUtils.cp(Rails.root.join("spec/fixtures/ss/logo.png"), file.path)
      end

      portlet.ad_file_ids = [ file.id ]
      portlet.link_urls = { file.id.to_s => "http://#{unique_id}.example.jp/" }
    end
  end

  factory :gws_portal_user_portlet, class: Gws::Portal::UserPortlet, traits: [:gws_portal_portlet_base] do
    portlet_model ''
  end

  factory :gws_portal_group_portlet, class: Gws::Portal::GroupPortlet, traits: [:gws_portal_portlet_base] do
    portlet_model ''
  end
end
