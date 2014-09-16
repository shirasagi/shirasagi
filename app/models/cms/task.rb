# coding: utf-8
class Cms::Task
  include SS::Task::Model
  include SS::Reference::Site

  belongs_to :node, class_name: "Cms::Node"
end
