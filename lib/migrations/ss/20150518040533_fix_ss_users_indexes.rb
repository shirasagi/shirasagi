class SS::Migration20150518040533
  def change
    unless valid_index?
      SS::User.remove_indexes
      SS::User.create_indexes
    end
  end

  def index_names
    @index_names ||= find_index_names
  end

  def valid_index?
    names = index_names
    if names.blank? || names.count > 1
      return false
    end

    name = names.first
    index = find_index_at(name)
    return sparse?(index)
  end

  def find_index_names
    SS::User.collection.indexes.select { |index| index["key"] == { "email" => 1 } }.map { |index| index["name"] }
  end

  def find_index_at(name)
    SS::User.collection.indexes.find { |index| index["name"] == name }
  end

  def sparse?(index)
    index["sparse"].present? && index["sparse"]
  end
end
