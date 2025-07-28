module Gws::Discussion::Searchable
  extend ActiveSupport::Concern

  included do
    field :body_text, type: String

    before_validation :set_body_text
  end

  private

  def set_body_text
    text = []
    text << contributor_name
    text << summary_text(nil)
    text += files.map(&:humanized_name)
    self.body_text = text.select(&:present?).map(&:squish).join("\r\n")
  end

  module ClassMethods
    def search(params = {})
      criteria = where({})
      return criteria if params.blank?

      if params[:topic].present?
        topic_id = params[:topic].to_i
        criteria = criteria.where("$or" => [
          { id: topic_id },
          { topic_id: topic_id }
        ])
      end
      if params[:body].present?
        criteria = criteria.keyword_in params[:body], :body_text
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
