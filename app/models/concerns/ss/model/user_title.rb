module SS::Model::UserTitle
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Fields::Normalizer
  include SS::Scope::ActivationDate

  included do
    store_in collection: "ss_user_titles"

    seqid :id
    field :name, type: String
    field :order, type: Integer, default: 0
    field :activation_date, type: DateTime
    field :expiration_date, type: DateTime

    belongs_to :group, class_name: "SS::Group"

    permit_params :name, :order, :activation_date, :expiration_date

    validates :name, presence: true, uniqueness: { scope: :group_id }, length: { maximum: 40 }
    validates :order, presence: true
    validates :group_id, presence: true
    validates :activation_date, datetime: true
    validates :expiration_date, datetime: true

    index({ group_id: 1, order: 1 })

    scope :search, ->(params) {
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    }
  end
end
