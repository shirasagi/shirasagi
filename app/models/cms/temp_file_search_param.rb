#frozen_string_literal: true

class Cms::TempFileSearchParam < SS::TempFileSearchParam
  AVAILABLE_TYPES = %w(temp_file user_file cms_file).freeze
  AVAILABLE_NODE_BOUNDS = %w(current all).freeze

  attr_accessor :cur_node, :node_bound

  validates :node_bound, inclusion: { in: AVAILABLE_NODE_BOUNDS, allow_blank: true }

  private

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

  def search_temp_file(model, base_criteria)
    criteria = Cms::TempFile.site(cur_site)
    if node_bound == "current"
      if cur_node
        criteria = criteria.node(cur_node)
      else
        criteria = criteria.exists(node_id: false)
      end
    end
    criteria = criteria.allow(:read, cur_user)
    criteria.pluck(:id)
  end

  def search_cms_file(model, base_criteria)
    Cms::File.site(cur_site).allow(:read, cur_user).pluck(:id)
  end
end
