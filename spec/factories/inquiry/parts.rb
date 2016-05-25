FactoryGirl.define do
  factory :inquiry_part_feedback, class: Inquiry::Part::Feedback, traits: [:cms_part] do
    route "inquiry/feedback"
  end
end
