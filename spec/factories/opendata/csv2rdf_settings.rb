FactoryGirl.define do
  factory :opendata_csv2rdf_setting, class: Opendata::Csv2rdfSetting do
    transient do
      site nil
      resource nil
    end

    site_id { site.present? ? site.id : nil }
    dataset_id { resource.dataset.id }
    resource_id { resource.id }
  end
end
