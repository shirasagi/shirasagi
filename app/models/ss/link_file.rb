class SS::LinkFile
  include SS::Model::File
  include SS::Relation::Thumb

  field :link_url, type: String

  default_scope ->{ where(model: "ss/link_file") }

  def previewable?(opts = {})
    public?
  end
end
