class Cms::GroupExporter
  include SS::GroupExporterBase

  self.mode = :cms
  attr_accessor :site
end
