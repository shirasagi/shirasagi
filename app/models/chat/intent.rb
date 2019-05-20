class Chat::Intent
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "chat_bots", :edit

  field :name, type: String
  field :phrase, type: SS::Extensions::Words
  field :response, type: SS::Extensions::Words

  permit_params :name, :phrase, :response

  validates :name, presence: true

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

    def response(string)
      return if string.blank?
      item = all.select do |intent|
        string =~ /#{intent.phrase.collect { |phrase| Regexp.escape(phrase) }.join('|') }/
      end.first
      return if item.blank?
      item.response.sample
    end
  end
end
