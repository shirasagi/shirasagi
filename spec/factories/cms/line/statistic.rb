FactoryBot.define do
  trait :cms_line_statistic do
    cur_site { cms_site }
    cur_user { cms_user }
    name { unique_id }
  end

  factory :cms_line_broadcast_statistic, class: Cms::Line::Statistic, traits: [:cms_line_statistic] do
    action { "broadcast" }
    request_id { unique_id }
    statistics {
      {
        overview: {
          requestId: request_id,
          timestamp: created.to_i,
          delivered: 600,
          uniqueImpression: 320,
          uniqueClick: nil,
          uniqueMediaPlayed: nil,
          uniqueMediaPlayed100Percent: nil
        }
      }
    }
  end

  factory :cms_line_multicast_statistic, class: Cms::Line::Statistic, traits: [:cms_line_statistic] do
    action { "multicast" }
    aggregation_unit { Cms::Line::Statistic.ss_short_uuid }
    member_count { 600 }
    aggregation_units_by_month { 0 }
    statistics {
      {
        overview: {
          uniqueImpression: 410,
          uniqueClick: nil,
          uniqueMediaPlayed: nil,
          uniqueMediaPlayed100Percent: nil
        }
      }
    }
  end
end
