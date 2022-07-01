class Cms::FormDb::ImportTask
  include SS::Model::Task

  field :import_url, type: String
  field :import_manually, type: Integer

  belongs_to :node, class_name: "Cms::Node"
  belongs_to :db, class_name: "Cms::FormDb"
end
