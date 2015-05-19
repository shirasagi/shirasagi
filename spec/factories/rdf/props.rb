FactoryGirl.define do
  factory :rdf_prop, class: Rdf::Prop do
    transient do
      vocab nil
      rdf_class nil
    end

    # vocab_id { vocab.present? ? vocab.id : nil }
    cur_vocab { vocab }
    name { unique_id }
    class_ids { rdf_class.present? ? [ rdf_class.id ] : nil }
  end
end
