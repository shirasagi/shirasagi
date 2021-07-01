class SS::ReplaceTempFile
  include SS::Model::File
  include SS::Relation::Thumb
  include SS::UserPermission

  default_scope ->{ where(model: "ss/replace_temp_file") }

  def remove_file
    Fs.rm_rf(path)
    remove_public_file
  end
end
