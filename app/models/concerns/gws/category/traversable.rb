module Gws::Category::Traversable
  extend ActiveSupport::Concern
  include Enumerable

  included do
    cattr_accessor :model_class, instance_accessor: false
  end

  class_methods do
    def build(site, user = nil)
      criteria = model_class.site(site)
      criteria = criteria.readable(user, site) if user
      raw_categories = criteria.to_a

      # build category hierarchy
      hierarchy_root = {}
      raw_categories.each do |category|
        parts = category.name.split('/')
        hierarchy = hierarchy_root
        parts.each do |n|
          hierarchy[n] ||= {}
          hierarchy = hierarchy[n]
        end
      end

      new(raw_categories, hierarchy_root)
    end
  end

  def initialize(categories, hierarchy, parent = nil)
    @categories = categories
    @hierarchy = hierarchy
    @parent = parent
  end

  def empty?
    @hierarchy.keys.empty?
  end

  def each
    @hierarchy.keys.each do |category|
      yield create_wrapper(category)
    end
  end

  def to_options(child = nil)
    if child
      options = [[option_name(child), child.id]]
      child.children.each { |c| options += to_options(c) }
      return options
    end

    options = []
    self.each { |c| options += to_options(c) }
    return options
  end

  def flatten
    expand_groups(self).flatten
  end

  def option_name(el)
    Gws::Category::Traversable.option_name(el.name, el.depth)
  end

  private
    def create_wrapper(name)
      full_name = @parent.present? ? "#{@parent}/#{name}" : name
      children = self.class.new(@categories, @hierarchy[name], full_name)
      category = @categories.find { |category| category.name == full_name }
      has_grandchild = children.any? { |child| child.children? }
      OpenStruct.new(
        id: category.try(:id),
        depth: full_name.count('/'),
        name: name,
        full_name: full_name,
        children: children,
        children?: children.present?,
        real?: category.present?,
        virtual?: category.blank?,
        color?: category.try(:color).present?,
        color: category.try(:color),
        text_color: category.try(:text_color),
        grandchild?: has_grandchild
      )
    end

    def expand_groups(groups)
      groups.map do |group|
        [ group ] + expand_groups(group.children)
      end
    end

  class << self
    def option_name(name, depth)
      depth = 0 if depth < 0
      indent = '&nbsp;' * 8 * depth + '+----'
      name = ERB::Util.html_escape(name)
      "#{indent} #{name}".html_safe
    end
  end
end
