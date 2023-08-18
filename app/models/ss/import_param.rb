class SS::ImportParam
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :cur_site, :cur_user, :in_file

  validates :in_file, presence: true
end
