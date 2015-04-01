class Chorg::Changeset
  extend SS::Translation
  include SS::Document
  include Cms::Permission

  TYPE_ADD = "add".freeze
  TYPE_MOVE = "move".freeze
  TYPE_UNIFY = "unify".freeze
  TYPE_DIVISION = "division".freeze
  TYPE_DELETE = "delete".freeze
  TYPES = [TYPE_ADD, TYPE_MOVE, TYPE_UNIFY, TYPE_DIVISION, TYPE_DELETE].freeze

  set_permission_name "cms_users", :edit

  attr_accessor :cur_revision, :cur_type

  GROUP_ATTRIBUTES = %w(name order contact_tel contact_fax contact_email ldap_dn).freeze

  seqid :id
  belongs_to :revision, class_name: "Chorg::Revision"
  field :type, type: String
  field :sources, type: Array
  field :destinations, type: Array
  permit_params :cur_revision, :cur_type
  permit_params :type, :sources, :destinations
  permit_params(sources: [ "id", "name"])
  permit_params(destinations: GROUP_ATTRIBUTES)

  validates :revision_id, presence: true
  validates :type, presence: true
  validates :sources, presence: true, if: -> { type != TYPE_ADD }
  validates :destinations, presence: true, if: -> { type != TYPE_DELETE }
  validate :validate_type
  validate :validate_sources, if: -> { type != TYPE_ADD }
  validate :validate_destinations, if: -> { type != TYPE_DELETE }
  before_validation :set_revision_id, if: ->{ @cur_revision }
  before_validation :set_type, if: ->{ @cur_type }
  before_validation :filter_source_blank_ids
  before_validation :filter_destination_blank_names
  before_save :set_source_names

  scope :revision, ->(revision) { where(revision_id: revision.id) }

  def before_unify
    return "" if sources.blank?
    sources.map {|s| s["name"] }.join(",")
  end

  def after_unify
    return "" if destinations.blank?
    destinations.map {|s| s["name"] }.join(",")
  end

  alias_method :add_description, :after_unify
  alias_method :before_move, :before_unify
  alias_method :after_move, :after_unify
  alias_method :before_division, :before_unify
  alias_method :after_division, :after_unify
  alias_method :delete_description, :before_unify

  private
    def set_revision_id
      self.revision_id ||= @cur_revision.id
    end

    def set_type
      self.type ||= @cur_type
    end

    def filter_source_blank_ids
      return if sources.blank?
      copy = sources.to_a.select { |s| s["id"].present? }
      self.sources = copy
    end

    def filter_destination_blank_names
      return if destinations.blank?
      copy = destinations.to_a.select { |s| s["name"].present? }
      self.destinations = copy
    end

    def validate_type
      errors.add :type, :invalid unless TYPES.include?(type)
    end

    def validate_sources
      return if sources.blank?
      blanks = sources.select { |s| Cms::Group.where(id: s["id"]).first.blank? }
      errors.add :sources, :invalid if blanks.present?
    end

    def validate_destinations
      return if destinations.blank?
      errors.add :destinations, :invalid unless destinations.select { |e| e["name"].blank? }.blank?
    end

    def set_source_names
      return if sources.blank?
      copy = sources.to_a.each { |s| s["name"] ||= Cms::Group.where(id: s["id"]).first.name }
      self.sources = copy
    end
end
