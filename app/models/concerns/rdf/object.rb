module Rdf::Object
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Rdf::Reference::Vocab

  included do
    seqid :id
    field :name, type: String
    field :labels, type: Rdf::Extensions::LangHash
    field :comments, type: Rdf::Extensions::LangHash

    permit_params :name, :labels, :comments
    permit_params labels: Rdf::Extensions::LangHash::LANGS
    permit_params comments: Rdf::Extensions::LangHash::LANGS

    before_validation :normalize_name

    validates :name, presence: true, length: { maximum: 80 }, uniqueness: { scope: :vocab_id }
    validate :validate_name

    scope :prefix_and_name, ->(prefix, name) { self.in(vocab_id: Rdf::Vocab.where(prefix: prefix).pluck(:id)).where(name: name) }
  end

  module ClassMethods
    def search(params)
      criteria = search_vocab(params)
      return criteria if params.blank?

      words = params[:name]
      words ||= params[:keyword]
      if words.present?
        words = words.split(/[\s　]+/).uniq.compact.map { |w| /\Q#{w}\E/i } if words.is_a?(String)
        criteria = criteria.all_in(name: words)
      end

      class_id = params[:class_id]
      if class_id.present?
        class_id = class_id.to_i if class_id.respond_to?(:to_i)
        criteria = criteria.in(class_ids: [class_id])
      end

      uri = params[:uri]
      if uri.present?
        prefix, name = Rdf::Vocab.qname(uri)
        criteria = criteria.prefix_and_name(prefix, name)
      end

      category_id = params[:category]
      if category_id.present?
        category_id = category_id.to_i if category_id.respond_to?(:to_i)
        criteria = criteria.in(category_ids: [category_id])
      end

      category_ids = params[:category_ids]
      if category_ids.present?
        # false means all
        category_ids = category_ids.map { |e| e == "false" ? false : e.to_i }
        criteria = criteria.in(category_ids: category_ids) unless category_ids.include?(false)
      end

      criteria
    end
  end

  private
    def normalize_name
      return if name.blank?
      # name must be NFKC
      self.name = UNF::Normalizer.normalize(self.name.strip, :nfkc)
    end

    def validate_name
      return if name.blank?
      # symbols is not allowed.
      errors.add :name, :invalid if name =~ /[\x00-,:-@\[-\^`\{-\x7f]/
    end

  public
    # view support method
    def preferred_label
      "#{vocab.prefix}:#{name}"
    end

    def uri
      "#{vocab.uri}#{name}"
    end
end
