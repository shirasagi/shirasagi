class SS::LogoFile
  include SS::Model::File
  include SS::Relation::Thumb

  default_scope ->{ where(model: "ss/logo_file") }

  def previewable?(_opts = {})
    true
  end
end
