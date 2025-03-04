#frozen_string_literal: true

class Cms::TempFileSearchParam < SS::TempFileSearchParam
  AVAILABLE_TYPES = %w(temp_file user_file cms_file).freeze
  AVAILABLE_NODE_BOUNDS = %w(current all).freeze

  attr_accessor :cur_node, :node_bound

  validates :node_bound, inclusion: { in: AVAILABLE_NODE_BOUNDS, allow_blank: true }

  private

  def validate_type
    unless self.types.all? { AVAILABLE_TYPES.include?(_1) }
      errors.add :types, :inclusion
    end
  end
end
