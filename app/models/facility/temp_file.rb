class Facility::TempFile
  include SS::Model::File
  include SS::UserPermission

  default_scope ->{ where(model: "facility/temp_file") }
end
