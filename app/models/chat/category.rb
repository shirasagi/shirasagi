class Chat::Category
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  index({ order: 1, updated: -1, site_id: 1, node_id: 1 }, { sparse: true } )

  set_permission_name "chat_bots"

  seqid :id
  field :name, type: String
  field :order, type: Integer

  belongs_to :node, class_name: "Chat::Node::Bot", inverse_of: :chat_categories

  permit_params :name, :order

  validates :name, presence: true, length: { maximum: 80 }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
