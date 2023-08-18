class Ezine::Task
  include SS::Model::Task

  belongs_to :page, class_name: "Cms::Page"
end
