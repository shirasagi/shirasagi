class Opendata::DatasetImporter
  include ActiveModel::Model
  include Sys::SiteImport::File

  attr_accessor :cur_site, :cur_user, :cur_node, :in_file

  class << self
    def t(*args)
      human_attribute_name(*args)
    end
  end
end
