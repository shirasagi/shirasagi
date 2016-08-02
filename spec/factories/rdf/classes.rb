FactoryGirl.define do
  factory :rdf_class, class: Rdf::Class do
    transient do
      vocab nil
    end

    # vocab_id { vocab.present? ? vocab.id : nil }
    cur_vocab { vocab }
    name { unique_id }
    labels { { "ja" => "日本語_#{unique_id}", "en" => "English_#{unique_id}" } }
  end
end
