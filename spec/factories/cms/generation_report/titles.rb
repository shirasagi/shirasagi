FactoryBot.define do
  factory :cms_generation_report_title, class: Cms::GenerationReport::Title do
    cur_site { cms_site }

    name { unique_id }
    sha256_hash { Digest::SHA256.hexdigest(SS::Crypto.salt + unique_id) }
  end
end
