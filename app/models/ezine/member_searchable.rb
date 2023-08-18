module Ezine::MemberSearchable
  extend ActiveSupport::Concern

  module ClassMethods
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :email
      end
      criteria
    end
  end
end
