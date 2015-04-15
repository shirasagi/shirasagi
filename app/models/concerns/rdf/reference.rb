module Rdf::Reference
  module Vocab
    extend ActiveSupport::Concern
    extend SS::Translation

    attr_accessor :cur_vocab

    included do
      belongs_to :vocab, class_name: "Rdf::Vocab"

      before_validation :set_vocab_id, if: ->{ @cur_vocab }

      validates :vocab_id, presence: true

      scope :site, ->(site) { self.in(vocab_id: Rdf::Vocab.site(site).pluck(:id)) }
      scope :vocab, ->(vocab) { where(vocab_id: vocab.id) }
    end

    module ClassMethods
      def search_vocab(params)
        criteria = self.where({})
        return criteria if params.blank?

        if params[:vocab].present?
          vocab_id = normalize_vocab_id(params[:vocab])
          criteria = criteria.where(vocab_id: vocab_id) if vocab_id
        end
        criteria
      end

      def normalize_vocab_id(vocab_id)
        case vocab_id
        when "false" then
          false
        else
          vocab_id.to_i
        end
      end
    end

    private
      def set_vocab_id
        self.vocab_id ||= @cur_vocab.id
      end
  end
end
