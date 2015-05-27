FactoryGirl.define do
  factory :cms_editor_template, class: Cms::EditorTemplate do
    transient do
      site nil
    end

    cur_site { site ? site : cms_site }
    name { "name-#{unique_id}" }
    description { "description-#{unique_id}" }
    html { "html-#{unique_id}"}
  end
end
