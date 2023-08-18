class Gws::Link
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Link
  include SS::Addon::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  cattr_accessor :default_link_target
  self.default_link_target = SS.config.gws.link["default_target"].presence || "_self"

  seqid :id
  field :name, type: String

  permit_params :name

  validates :name, presence: true, length: { maximum: 80 }

  default_scope -> {
    order_by released: -1
  }

  class << self
    def search(params)
      all.search_keyword(params)
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in params[:keyword], :name, "links.name", "links.url"
    end
  end
end
