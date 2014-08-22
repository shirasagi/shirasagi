# coding: utf-8
class Opendata::DatasetFile
  include Opendata::File::Model

  default_scope ->{ where(model: "opendata/dataset_file") }
end
