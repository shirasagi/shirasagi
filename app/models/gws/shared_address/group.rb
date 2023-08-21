class Gws::SharedAddress::Group
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :order

  validates :name, presence: true, uniqueness: { scope: :site_id }

  default_scope ->{ order_by order: 1 }

  class << self
    def search(params)
      all.search_name(params).search_keyword(params)
    end

    def search_name(params)
      return all if params.blank? || params[:name].blank?
      all.search_text(params[:name])
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in(params[:keyword], :name)
    end
  end
end
