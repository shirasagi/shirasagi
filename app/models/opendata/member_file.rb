class Opendata::MemberFile
  include SS::Model::File
  include Cms::Reference::Member
  include Cms::Lgwan::File

  default_scope ->{ where(model: "opendata/member") }

  def previewable?(site: nil, user: nil, member: nil)
    # opendata's profile icon is always public
    true
  end
end
