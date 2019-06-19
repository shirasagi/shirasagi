module Chorg::Model::Changeset
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  TYPE_ADD = 'add'.freeze
  TYPE_MOVE = 'move'.freeze
  TYPE_UNIFY = 'unify'.freeze
  TYPE_DIVISION = 'division'.freeze
  TYPE_DELETE = 'delete'.freeze
  TYPES = [TYPE_ADD, TYPE_MOVE, TYPE_UNIFY, TYPE_DIVISION, TYPE_DELETE].freeze

  included do
    attr_accessor :cur_revision, :cur_type

    seqid :id
    field :type, type: String
    field :sources, type: Array
    field :destinations, type: Array
    permit_params :cur_revision, :cur_type
    permit_params :type, :sources, :destinations
    permit_params(sources: %w(id name))
    permit_params(destinations: self::GROUP_ATTRIBUTES)

    validates :revision_id, presence: true
    validates :type, presence: true
    validates :sources, presence: true, if: -> { type != TYPE_ADD }
    validates :destinations, presence: true, if: -> { type != TYPE_DELETE }
    validate :validate_type
    validate :validate_sources, if: -> { type != TYPE_ADD }
    validate :validate_destinations, if: -> { type != TYPE_DELETE }
    validate :validate_division_destinations, if: -> { type == TYPE_DIVISION }
    before_validation :set_revision_id, if: ->{ @cur_revision }
    before_validation :set_type, if: ->{ @cur_type }
    before_validation :filter_source_blank_ids
    before_validation :filter_destination_blank_names
    before_save :set_source_names

    scope :revision, ->(revision) { where(revision_id: revision.id) }
  end

  def before_unify
    return '' if sources.blank?
    sources.map { |s| s['name'] }.join(',')
  end

  def after_unify
    return '' if destinations.blank?
    destinations.map { |s| s['name'] }.join(',')
  end

  alias add_description after_unify
  alias before_move before_unify
  alias after_move after_unify
  alias before_division before_unify
  alias after_division after_unify
  alias delete_description before_unify

  private

  def set_revision_id
    self.revision_id ||= @cur_revision.id
  end

  def set_type
    self.type ||= @cur_type
  end

  def filter_source_blank_ids
    return if sources.blank?
    copy = sources.to_a.select { |s| s['id'].present? }
    self.sources = copy
  end

  def filter_destination_blank_names
    return if destinations.blank?
    copy = destinations.to_a.select { |s| s['name'].present? }
    self.destinations = copy
  end

  def validate_type
    errors.add :type, :invalid unless TYPES.include?(type)
  end

  def validate_sources
    return if sources.blank?
    blanks = sources.select { |s| Cms::Group.where(id: s['id']).first.blank? }
    errors.add :sources, :invalid if blanks.present?
  end

  def validate_destinations
    return if destinations.blank?
    errors.add :destinations, :invalid unless destinations.select { |e| e['name'].blank? }.blank?
  end

  def validate_division_destinations
    return if destinations.blank?

    if destinations.size > 3
      errors.add :destinations, :less_than_or_equal_to, count: 3
    end
  end

  def set_source_names
    return if sources.blank?
    copy = sources.to_a.each { |s| s['name'] ||= Cms::Group.where(id: s['id']).first.name }
    self.sources = copy
  end
end
