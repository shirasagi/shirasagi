class Chat::Intent
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Chat::Addon::Category
  include History::Addon::Backup

  index({ order: 1, site_id: 1 })

  set_permission_name "chat_bots", :edit

  seqid :id
  field :name, type: String
  field :phrase, type: SS::Extensions::Words
  field :suggest, type: SS::Extensions::Words
  field :response, type: String
  field :order, type: Integer

  permit_params :name, :phrase, :suggest, :response, :order

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

    def find_intent(string)
      return if string.blank?
      item = all.select do |intent|
        string =~ /#{intent.phrase.collect { |phrase| Regexp.escape(phrase) }.join('|') }/
      end.first
      return if item.blank?
      item
    end

    def response(string)
      item = find_intent(string)
      return if item.blank?
      item.response
    end
  end
end
