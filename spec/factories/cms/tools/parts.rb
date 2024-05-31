FactoryBot.define do
  factory :accessibilty_tool, class: 'Cms::Part::Free' do
    name { unique_id.to_s }
    basename { "tool.part.html" }
    filename { "tool.part.html" }
    html do
      ::File.read("#{Rails.root}/db/seeds/demo/parts/tool.part.html")
    end
  end
end
