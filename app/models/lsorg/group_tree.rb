class Lsorg::GroupTree
  include Enumerable

  attr_reader :group_names, :item_by_name

  def initialize(root_group, exclude_groups = [])
    @exclude_group_names = root_only(exclude_groups).map(&:name)

    groups = Cms::Group.where(name: /^#{root_group.name}(\/|$)/).active
    groups = groups.tree_sort(root_name: dirname(root_group.name))
    @group_names = groups.map(&:name).reject { |name| exclude?(name) }

    @item_by_name = {}
    groups.each do |group|
      next if exclude?(group.name)

      item = Lsorg::GroupItem.new
      item.delegate_proc = proc do |caller, method|
        send(method, caller)
      end

      item.group = group
      item.name = group.trailing_name
      item.depth = group.depth
      item.order = group.order
      item.basename = group.basename

      @root ||= item
      @item_by_name[group.name] = item
    end
  end

  def to_a
    item_by_name.values
  end

  def to_h
    item_by_name
  end

  def each(&block)
    to_a.each(&block)
  end

  def tree(item = nil)
    self
  end

  def root(item = nil)
    @root
  end

  def root?(item = nil)
    @root == item
  end

  def parent(item)
    name = item.group.name
    while name = dirname(name)
      parent = item_by_name[name]
      break if parent
    end
    parent
  end

  def full_name(item)
    return item.name if item.parent.nil?
    "#{full_name(item.parent)}/#{item.name}"
  end

  def filename(item)
    return item.basename if item.parent.nil?
    "#{filename(item.parent)}/#{item.basename}"
  end

  def descendants(item)
    name = item.group.name
    names = group_names.select { |n| n.start_with?(name + "/") }
    names.filter_map { |name| item_by_name[name] }
  end

  def children(item)
    descendant_items = descendants(item)
    descendant_items.select { |descendant_item| descendant_item.depth == (item.depth + 1) }
  end

  private

  def exclude?(name)
    @exclude_group_names.find { |n| name == n || name.start_with?(n + "/") }.present?
  end

  def dirname(name)
    return nil if name.count("/") == 0
    name.sub(/\/[^\/]*$/, "")
  end

  def root_only(groups)
    names = groups.map(&:name)
    names = names.select do |name|
      parent = names.find { |n| name.start_with?("#{n}/") }
      parent.nil?
    end
    names.map { |name| groups.find { |g| g.name == name } }
  end

  class << self
    def build(root_group, exclude_groups = [])
      new(root_group, exclude_groups).root
    end
  end
end
