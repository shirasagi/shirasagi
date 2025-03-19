#frozen_string_literal: true

class SS::TempFileSearchParam
  include ActiveModel::Model
  include SS::PermitParams

  AVAILABLE_TYPES = %w(temp_file user_file cms_file).freeze
  AVAILABLE_NODE_BOUNDS = %w(current all).freeze

  attr_accessor :ss_mode, :cur_site, :cur_user, :cur_node, :accepts, :types, :node_bound, :keyword

  validates :node_bound, inclusion: { in: AVAILABLE_NODE_BOUNDS, allow_blank: true }
  validate :normalize_types
  validate :validate_types

  permit_params :node_bound, :keyword, types: []

  def set_default
    if types.blank? && node_bound.blank?
      self.types = %w(temp_file)
      self.node_bound = "current"
    end
  end

  def query(model, base_criteria)
    return base_criteria.none if invalid?

    all_ids = union_all_file_ids(model, base_criteria)
    return base_criteria.none if all_ids.blank?

    criteria = base_criteria.in(id: all_ids)
    if keyword.present?
      fields = %i[name filename]

      words = keyword.split(/[\s　]+/).uniq.compact.map { |w| /#{::Regexp.escape(w)}/i }
      words = words[0..4]
      conditions = words.map do |word|
        { "$or" => fields.map { |field| { field => word } } }
      end

      criteria = criteria.where("$and" => conditions)
    end
    if accepts.present?
      content_types = accepts
        .map { SS::MimeType.find(_1, nil) }.compact.uniq
        .reject { _1 == SS::MimeType::DEFAULT_MIME_TYPE }
      criteria = criteria.in(content_type: content_types) if content_types.present?
    end

    criteria
  end

  private

  def normalize_types
    self.types = Array(types).select(&:present?)
  end

  def validate_types
    unless self.types.all? { AVAILABLE_TYPES.include?(_1) }
      errors.add :types, :inclusion
    end
  end

  def union_all_file_ids(model, base_criteria)
    all_ids_set = Set.new

    if types && types.include?("temp_file")
      all_ids_set += search_temp_file(model, base_criteria)
    end
    if types && types.include?("user_file")
      all_ids_set += search_user_file(model, base_criteria)
    end
    if types && types.include?("cms_file")
      all_ids_set += search_cms_file(model, base_criteria)
    end

    all_ids_set.to_a
  end

  def search_temp_file(_model, _base_criteria)
    case ss_mode
    when :cms
      criteria = Cms::TempFile.site(cur_site)
      if node_bound == "current"
        if cur_node
          criteria = criteria.node(cur_node)
        else
          criteria = criteria.exists(node_id: false)
        end
      end
    else # :gws
      criteria = SS::TempFile.all
    end
    criteria = criteria.allow(:read, cur_user)
    criteria.pluck(:id)
  end

  def search_user_file(_model, _base_criteria)
    SS::UserFile.user(cur_user).pluck(:id)
  end

  def search_cms_file(model, base_criteria)
    Cms::File.site(cur_site).allow(:read, cur_user).pluck(:id)
  end
end
