#frozen_string_literal: true

class SS::TempFileSearchParam
  include ActiveModel::Model

  AVAILABLE_TYPES = %w(temp_file user_file).freeze

  attr_accessor :cur_site, :cur_user, :types

  validate :normalize_types
  validate :validate_types

  private

  def normalize_types
    self.types = Array(types).select(&:present?)
  end

  def validate_types
    unless self.types.all? { AVAILABLE_TYPES.include?(_1) }
      errors.add :types, :inclusion
    end
  end
end
