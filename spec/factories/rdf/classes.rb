FactoryGirl.define do
  factory :rdf_class, class: Rdf::Class do
    transient do
      vocab nil
    end

    vocab_id { vocab.present? ? vocab.id : nil }
    name { unique_id }
  end
end
