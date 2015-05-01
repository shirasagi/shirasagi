class Rdf::Vocab
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::Permission

  DEFAULT_ORDER = 100.freeze

  OWNER_SYSTEM = "system".freeze
  OWNER_USER = "user".freeze
  OWNERS = [OWNER_SYSTEM, OWNER_USER].freeze

  index({ site_id: 1, uri: 1 }, { unique: true })

  set_permission_name "cms_users", :edit

  default_scope ->{ order(order: 1, id: 1) }

  seqid :id
  field :prefix, type: String
  field :uri, type: String
  field :order, type: Integer, default: DEFAULT_ORDER
  field :labels, type: Rdf::Extensions::LangHash
  field :comments, type: Rdf::Extensions::LangHash
  field :creators, type: Array
  field :license, type: String
  field :version, type: String
  field :published, type: String
  field :owner, type: String, default: Rdf::Vocab::OWNER_USER
  has_many :classes, class_name: "Rdf::Class", dependent: :destroy
  has_many :props, class_name: "Rdf::Prop", dependent: :destroy

  permit_params :prefix, :uri, :order, :labels, :comments, :creators, :license, :version, :published
  permit_params labels: Rdf::Extensions::LangHash::LANGS
  permit_params comments: Rdf::Extensions::LangHash::LANGS
  permit_params creators: [{names: Rdf::Extensions::LangHash::LANGS}, "homepage"]

  before_validation :normalize_uri
  validates :prefix, presence: true, length: { maximum: 16 }, uniqueness: { scope: :site_id }
  validates :uri, presence: true, length: { maximum: 200 }, uniqueness: { scope: :site_id }
  validates :order, presence: true
  validates :owner, presence: true
  validate :validate_prefix
  validate :validate_uri
  validate :validate_owner
  validate :validate_labels

  class << self
    def qname(uri)
      return nil if uri.blank?
      # consider about caching if this method is too slow.
      vocab = self.each.find { |vocab| uri.start_with?(vocab.uri) }
      if vocab
        [vocab.prefix, uri.gsub(vocab.uri, "")]
      else
        RDF::URI.new(uri).qname
      end
    end

    def pname(uri)
      qname(uri).try(:join, ":") || uri
    end

    def owner_options
      options = []
      OWNERS.each do |owner|
        options << [I18n.t("rdf.vocabs.owner_#{owner}"), owner]
      end
      options
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      keyword = params[:keyword]
      if keyword.present?
        keyword = keyword.split(/[\s　]+/).uniq.compact.map { |w| /\Q#{w}\E/i } if keyword.is_a?(String)
        criteria = criteria.or({ "labels.ja" => { "$all" => keyword } },
                               { "labels.en" => { "$all" => keyword } },
                               { "labels.invariant" => { "$all" => keyword } })
      end

      criteria
    end

    def normalize_uri(uri)
      return uri if uri.blank?
      uri = "#{uri}#" if /[\/#]$/ !~ uri
      uri
    end
  end

  private
    def normalize_uri
      self.uri = self.class.normalize_uri(self.uri)
    end

    def validate_prefix
      return if prefix.blank?
      errors.add :prefix, :reserved_prefix if prefix == "endemic_vocab"
    end

    def validate_uri
      errors.add :uri, :invalid if /[\/#]$/ !~ self.uri
    end

    def validate_owner
      return if owner.blank?
      errors.add :owner, :invalid unless OWNERS.include?(owner)
    end

    def validate_labels
      errors.add :labels, :blank if labels.blank? || labels.preferred_value.blank?
    end
end
