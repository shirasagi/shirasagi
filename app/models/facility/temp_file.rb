class Facility::TempFile
  include SS::Model::File

  default_scope ->{ where(model: "facility/temp_file") }
end
