class Facility::TempFile
  include SS::File::Model

  default_scope ->{ where(model: "facility/temp_file") }
end
