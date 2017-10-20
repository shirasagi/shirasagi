class Gws::Facility::CustomField
  include SS::Document
  include Gws::Addon::CustomField
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Reference::Facility::Item

  field :name, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :order

  validates :name, presence: true, length: { maximum: 80 }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in(params[:keyword], :name)
      end

      criteria
    end
  end
end
