class Gws::Group
  include SS::Model::Group
  include Gws::SitePermission

  has_many :users, foreign_key: :group_ids, class_name: "Gws::User"

  scope :site, ->(site) { where name: /^#{Regexp.escape(site.name)}(\/|$)/ }
end
