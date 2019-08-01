class SS::Migration20181218120000
  include SS::Migration::Base

  depends_on "20181218000000"

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
    return !unique?(index)
  end

  def find_index_names
    key = {"organization_uid" => 1, "organization_id" => 1 }
    SS::User.collection.indexes.select { |index| index["key"] == key }.map { |index| index["name"] }
  end

  def find_index_at(name)
    SS::User.collection.indexes.find { |index| index["name"] == name }
  end

  def unique?(index)
    index["unique"].present? && index["unique"]
  end
end
