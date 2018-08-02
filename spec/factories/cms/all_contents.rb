FactoryBot.define do
  factory :cms_all_content, class: OpenStruct do
    route { "cms/#{unique_id}" }
    name { "name-#{unique_id}" }
    index_name { "index_name-#{unique_id}" }
    filename { "filename-#{unique_id}" }
    url { "http://#{unique_id}.example.jp/#{unique_id}/" }
    layout { "#{unique_id}.layout.html" }
    keywords { unique_id }
    description { unique_id }
    summary_html { unique_id }
    sort { %w(name filename created updated released order).sample }
    limit { rand(100) }
    upper_html { "upper-#{unique_id}" }
    loop_html { "loop-#{unique_id}" }
    lower_html { "lower-#{unique_id}" }
    new_days { rand(10) }
    group_names { unique_id }
    status { I18n.t("ss.options.state.#{%w(public closed).sample}") }
  end
end
