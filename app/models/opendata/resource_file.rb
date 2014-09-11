# coding: utf-8
module Opendata::ResourceFile
  include SS::File::Model

  default_scope ->{ where(model: "opendata/resource_file") }
end
