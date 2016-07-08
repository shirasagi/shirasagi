FactoryGirl.define do
  factory :cms_body_layout, class: Cms::BodyLayout do
    cur_site { cms_site }
    cur_user { cms_user }
    name "body_layout"
    filename { "#{name}.layout.html" }
    parts { %w(part1 part2 part3) }
    html do
      '<div><p class="yield0">{{ yield 0 }}</p><p class="yield1">{{ yield 1 }}</p><p class="yield2">{{ yield 2 }}</p></div>'
    end
  end
end
