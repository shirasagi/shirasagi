FactoryGirl.define do
  factory :uploader_node_base, class: Uploader::Node::Base, traits: [:cms_node] do
    route "uploader/base"
  end

  factory :uploader_node_file, class: Uploader::Node::File, traits: [:cms_node] do
    route "uploader/file"
  end
end
