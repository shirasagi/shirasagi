class SS::LogoFile
  include SS::Model::File
  include SS::Relation::Thumb

  default_scope ->{ where(model: "ss/logo_file") }

  def previewable?(site: nil, user: nil, member: nil)
    true
  end
end
