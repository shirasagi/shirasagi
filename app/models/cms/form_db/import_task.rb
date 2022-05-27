class Cms::FormDb::ImportTask
  include SS::Model::Task

  field :import_url, type: String

  belongs_to :node, class_name: "Cms::Node"
  belongs_to :db, class_name: "Cms::FormDb"
end
