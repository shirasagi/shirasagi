FactoryBot.define do
  factory :opendata_csv2rdf_setting, class: Opendata::Csv2rdfSetting do
    transient do
      resource { nil }
    end

    cur_site { cms_site }
    dataset_id { resource.dataset.id }
    resource_id { resource.id }
  end

  factory :opendata_csv2rdf_setting_geo, class: Opendata::Csv2rdfSetting do
    transient do
      rdf_class { nil }
    end

    class_id { rdf_class.id }
    header_rows { 1 }
    header_labels { [%w(場所), %w(緯度), %w(経度), %w(実行結果)] }
    column_types do
      prefix = rdf_class.vocab.prefix
      array = []

      %w(場所 緯度 経度 実行結果).each do |label|
        rdf_class.properties.find_by(name: label).try do |prop|
          hash = {
            "ids" => [ prop.id ],
            "names" => [ label ],
            "properties" => [ "#{prefix}:#{label}" ],
            "comments" => [ nil ]
          }

          prop.range.try do |range|
            hash["classes"] = [ range.preferred_label ]
          end

          array << hash
        end
      end

      array
    end
  end
end
