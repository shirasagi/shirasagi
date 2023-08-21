FactoryBot.define do
  factory :image_map_node_page, class: ImageMap::Node::Page, traits: [:cms_node] do
    route { "image_map/page" }
    image do
      SS::TmpDir.tmp_ss_file(site: cur_site,
        contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg", basename: 'keyvisual.jpg')
    end
    area_states { [ {"name1" => "value1"}, { "name2" => "value2" }, { "name3" => "value3" } ] }
  end
end
