module Gws::Workload::Yearly
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :year, type: Integer

    permit_params :year

    validates :year, presence: true
  end

  class_methods do
    def search_year(params)
      return all if params.blank? || params[:year].blank?
      return all unless params[:year].to_s.match?(/\A\d+\z/)

      all.where(year: params[:year].to_i)
    end
  end
end
