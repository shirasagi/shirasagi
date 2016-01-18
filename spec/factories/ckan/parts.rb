FactoryGirl.define do
  factory :ckan_part_status, class: Ckan::Part::Status do
    site_id { ss_site.id }
    name "#{unique_id}"
    filename { "#{name}.part.html" }
    route "ckan/status"
    ckan_url "http://example.com"
    ckan_status "dataset"
  end
end
