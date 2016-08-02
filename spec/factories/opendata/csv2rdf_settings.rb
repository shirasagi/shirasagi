FactoryGirl.define do
  factory :opendata_csv2rdf_setting, class: Opendata::Csv2rdfSetting do
    transient do
      resource nil
    end

    cur_site { cms_site }
    dataset_id { resource.dataset.id }
    resource_id { resource.id }
  end
end
