module Rdf::Object
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Rdf::LangHash

  included do
    seqid :id
    belongs_to :vocab, class_name: "Rdf::Vocab"
    field :name, type: String
    field :labels, type: Hash
    field :comments, type: Hash
    field :equivalent, type: String

    permit_params :name, :labels, :comments, :equivalent
    permit_params labels: ["ja", "en", "invariant"]
    permit_params comments: ["ja", "en", "invariant"]

    before_validation :normalize_labels
    before_validation :normalize_comments
    validates :vocab, presence: true
    validates :name, presence: true, length: { maximum: 40 }, uniqueness: { scope: :vocab_id }
    validate :validate_name

    scope :site, ->(site) { self.in(vocab_id: Rdf::Vocab.site(site).pluck(:id)) }
    scope :vocab, ->(vocab) { where(vocab_id: vocab.id) }
  end

  module ClassMethods
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        # criteria = criteria.search_text params[:name]
        words = params[:name]
        words = words.split(/[\s　]+/).uniq.compact.map { |w| /\Q#{w}\E/i } if words.is_a?(String)
        criteria = criteria.all_in(:name => words)
      end
      # if params[:keyword].present?
      #   criteria = criteria.keyword_in params[:keyword], :name, :html
      # end
      if params[:vocab].present?
        vocab_id = params[:vocab]
        vocab_id = case vocab_id
        when "false" then
          false
        else
          vocab_id.to_i
        end
        criteria = criteria.where(vocab_id: vocab_id) if vocab_id
      end
      criteria
    end
  end

  public
    def label
      lang_hash_value labels
    end

    def comment
      lang_hash_value comments
    end

  private
    def validate_name
      return if name.blank?
      # symbols is not allowed.
      errors.add :name, :invalid if name =~ /[\x00-,\.-\/:-@\[-\^`\{-\x7f]/
    end

    def normalize_labels
      self.labels = normalize_lang_hash labels
    end

    def normalize_comments
      self.comments = normalize_lang_hash comments
    end
end
