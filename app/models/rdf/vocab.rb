class Rdf::Vocab
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::Permission
  include Rdf::LangHash

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
  field :labels, type: Hash
  field :comments, type: Hash
  field :creators, type: Array
  field :license, type: String
  field :version, type: String
  field :published, type: String
  field :owner, type: String, default: Rdf::Vocab::OWNER_USER
  has_many :classes, class_name: "Rdf::Class", dependent: :destroy
  has_many :props, class_name: "Rdf::Prop", dependent: :destroy

  permit_params :prefix, :uri, :order, :labels, :comments, :creators, :license, :version, :published
  permit_params labels: %w(ja en invariant)
  permit_params comments: %w(ja en invariant)
  permit_params creators: [{names: %w(ja en invariant)}, "homepage"]

  before_validation :check_uri
  before_validation :normalize_labels
  before_validation :normalize_comments
  validates :prefix, presence: true, length: { maximum: 16 }, uniqueness: { scope: :site_id }
  validates :uri, presence: true, length: { maximum: 200 }, uniqueness: { scope: :site_id }
  validates :owner, presence: true
  validate :validate_uri
  validate :validate_owner

  class << self
    def qname(uri)
      return ["", uri] if uri.blank?
      # consider about caching if this method is too slow.
      vocab = self.each.select { |vocab| uri.start_with?(vocab.uri) }.first
      if vocab
        [vocab.prefix, uri.gsub(vocab.uri, "")]
      else
        RDF::URI.new(uri).qname
      end
    end

    def pname(uri)
      return uri if uri.blank?
      qname(uri).join(":")
    end

    def owner_options
      options = []
      OWNERS.each do |owner|
        options << [I18n.t("rdf.vocabs.owner_#{owner}"), owner]
      end
      options
    end
  end

  def label
    lang_hash_value labels
  end

  private
    def check_uri
      return if self.uri.blank?
      if /[\/#]$/ !~ self.uri
        self.uri = self.uri + "#"
      end
    end

    def validate_uri
      errors.add :uri, :invalid if /[\/#]$/ !~ self.uri
    end

    def normalize_labels
      self.labels = normalize_lang_hash labels
    end

    def normalize_comments
      self.comments = normalize_lang_hash comments
    end

    def validate_owner
      return if owner.blank?
      errors.add :owner, :invalid unless OWNERS.include?(owner)
    end
end
