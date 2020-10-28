class Cms::AttachedFileAttribute
  include Mongoid::Document

  belongs_to :page, class_name: "Cms::Page"
  belongs_to :file, class_name: "SS::File"

  field :url, type: String
  field :full_url, type: String
  field :name, type: String
  field :filename, type: String
  field :extname, type: String
  field :size, type: Integer

  field :geo_location, type: Map::Extensions::Loc
  field :csv_headers, type: Array

  def initialize_from_file(file)
    self.file = file
    self.url = file.url
    self.full_url = file.full_url
    self.name = file.name
    self.filename = file.filename
    self.size = file.size
    self.geo_location = file.geo_location
    self.csv_headers = file.csv_headers
    self.extname = file.extname
  end
end
