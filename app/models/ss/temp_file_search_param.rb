#frozen_string_literal: true

class SS::TempFileSearchParam
  include ActiveModel::Model

  AVAILABLE_TYPES = %w(temp_file user_file).freeze

  attr_accessor :cur_site, :cur_user, :types, :keyword

  validate :normalize_types
  validate :validate_types

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

    all_ids_set.to_a
  end

  def search_temp_file(_model, _base_criteria)
    SS::TempFile.all.pluck(:id)
  end

  def search_user_file(_model, _base_criteria)
    SS::UserFile.user(cur_user).pluck(:id)
  end
end
