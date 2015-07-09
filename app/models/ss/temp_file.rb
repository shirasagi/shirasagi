class SS::TempFile
  include SS::Model::File
  include SS::Relation::Thumb
  include SS::UserPermission

  default_scope ->{ where(model: "ss/temp_file") }
end
