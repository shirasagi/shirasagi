FactoryBot.define do
  factory :inquiry_part_feedback, class: Inquiry::Part::Feedback, traits: [:cms_part] do
    route { "inquiry/feedback" }
    cur_node { create :inquiry_node_form, cur_site: cur_site }
  end
end
