FactoryBot.define do
  factory :translate_part_tool, class: Translate::Part::Tool, traits: [:cms_part] do
    route "translate/tool"
    ajax_view "enabled"
  end
end
