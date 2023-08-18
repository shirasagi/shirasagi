class Gws::Memo::List
  extend SS::Translation
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  # member_include_custom_groups
  readable_setting_include_custom_groups
  permission_include_custom_groups

  field :name, type: String
  field :sender_name, type: String
  field :signature, type: String
  embeds_ids :categories, class_name: 'Gws::Memo::Category'

  has_many :messages, class_name: 'Gws::Memo::ListMessage', dependent: :nullify

  permit_params :name, :sender_name, :signature, category_ids: []

  validates :name, presence: true, length: { maximum: 80 }

  class << self
    def search(params)
      all.search_name(params).search_keyword(params).search_category(params)
    end

    def search_name(params)
      return all if params.blank? || params[:name].blank?
      all.search_text(params[:name])
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in(params[:keyword], :name)
    end

    def search_category(params)
      return all if params.blank? || params[:category_id].blank?
      all.where(category_ids: params[:category_id])
    end
  end
end
