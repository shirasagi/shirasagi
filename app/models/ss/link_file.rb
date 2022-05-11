class SS::LinkFile
  include SS::Model::File

  field :link_url, type: String

  default_scope ->{ where(model: "ss/link_file") }

  def previewable?(site: nil, user: nil, member: nil)
    public?
  end
end
