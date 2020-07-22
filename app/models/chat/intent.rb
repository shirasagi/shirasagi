class Chat::Intent
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User
  include Chat::Addon::Category
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  index({ order: 1, name: 1, updated: -1, site_id: 1, node_id: 1 })

  set_permission_name "chat_bots"

  seqid :id
  field :name, type: String
  field :phrase, type: SS::Extensions::Words
  field :suggest, type: SS::Extensions::Words
  field :response, type: String
  field :question, type: String
  field :site_search, type: String
  field :order, type: Integer

  belongs_to :node, class_name: "Chat::Node::Bot", inverse_of: :intents

  permit_params :name, :phrase, :suggest, :response, :question, :site_search, :order

  validates :name, presence: true, length: { maximum: 80 }
  validates :phrase, presence: true
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :phrase, :suggest, :response
      end
      criteria
    end

    def csv_headers
      %w(
          id name phrase suggest response site_search order category_ids
        )
    end

    def csv
      CSV.generate do |data|
        data << csv_headers.map { |k| t k }
        criteria.each do |item|
          data << [
            item.id,
            item.name,
            item.phrase.join("\n"),
            item.suggest.join("\n"),
            item.response,
            item.site_search,
            item.order,
            item.categories.pluck(:name).join("\n")
          ]
        end
      end
    end

    def intents(string)
      return if string.blank?

      all.select do |intent|
        intent.phrase.push(intent.name).any? { |phrase| string.include?(phrase) }
      end
    end

    def find_intent(string)
      return if string.blank?

      all.entries.find do |intent|
        intent.phrase.push(intent.name).any? { |phrase| string.include?(phrase) }
      end
    end

    def response(string)
      item = find_intent(string)
      item.try(:response)
    end
  end

  def question_options
    %w(disabled enabled).map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }
  end
  alias site_search_options question_options

  def duplicate?
    self.class.site(site).where(node_id: node_id).intents(phrase.join).count > 1
  end
end
