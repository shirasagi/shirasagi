FactoryBot.define do
  factory :ckan_part_status, class: Ckan::Part::Status, traits: [:cms_part] do
    route { "ckan/status" }
    ckan_url { "http://example.com" }
    ckan_basicauth_state { "disabled" }
    ckan_status { "dataset" }
  end

  factory :ckan_part_page, class: Ckan::Part::Page, traits: [:cms_part] do
    route { "ckan/page" }
  end

  factory :ckan_part_reference, class: Ckan::Part::Reference, traits: [:cms_part] do
    route { "ckan/reference" }
  end
end
