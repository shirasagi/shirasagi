module SS::Model::UserTitle
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Fields::Normalizer

  included do
    store_in collection: "ss_user_titles"

    seqid :id
    field :name, type: String
    field :order, type: Integer, default: 0

    belongs_to :group, class_name: "SS::Group"

    permit_params :name, :order

    validates :name, presence: true, length: { maximum: 40 }
    validates :order, presence: true
    validates :group_id, presence: true

    index({ group_id: 1, order: 1})

    scope :search, ->(params) {
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    }
  end
end
