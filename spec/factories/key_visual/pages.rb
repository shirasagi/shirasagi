FactoryBot.define do
  factory :key_visual_image, class: KeyVisual::Image, traits: [:cms_page] do
    cur_site { cms_site }
    filename { unique_id }
    route "key_visual/image"
    link_url "/example/"
    file { SS::TmpDir.tmp_ss_file(site: cur_site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", basename: 'logo.png') }
  end
end
