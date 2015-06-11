class SS::TempFile
  include SS::Model::File

  default_scope ->{ where(model: "ss/temp_file") }
end
