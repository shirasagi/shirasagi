class Cms::Task
  include SS::Model::Task
  include SS::Reference::Site

  belongs_to :node, class_name: "Cms::Node"
end
