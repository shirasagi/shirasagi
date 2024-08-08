class Cms::Node::Importer
  # TODO and Memo:
  # if Cms::NodeImportBase not used other class
  # can write your logic directly here
  include Cms::NodeImportBase

  self.model = Cms::Node
end