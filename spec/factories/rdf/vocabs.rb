FactoryGirl.define do
  factory :rdf_vocab, class: Rdf::Vocab do
    transient do
      site nil
    end

    site_id { site.present? ? site.id : nil }
    prefix { unique_id }
    uri { "http://example.jp/#{prefix}/rdf#" }
    labels { { "ja": unique_id } }
  end
end
