FactoryBot.define do
  factory :inquiry_part_feedback, class: Inquiry::Part::Feedback, traits: [:cms_part] do
    route { "inquiry/feedback" }
    # 本パーツには親フォルダー "inquiry/form" が必要
    cur_node { create :inquiry_node_form, cur_site: cur_site }
  end
end
