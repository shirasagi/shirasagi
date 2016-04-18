module Gws::Category::Traversable
  extend ActiveSupport::Concern
  include Enumerable

  included do
    cattr_accessor :model_class, instance_accessor: false
  end

  class_methods do
    def build(site, user = nil)
      criteria = model_class.site(site)
      criteria = criteria.target_to(user) if user
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
    @hierarchy.keys.sort.each do |category|
      yield create_wrapper(category)
    end
  end

  def to_options(child = nil)
    if child
      indent = '-' * child.depth
      options = [["#{indent} #{child.name}".html_safe, child.id]]
      child.children.each { |c| options += to_options(c) }
      return options
    end

    options = []
    self.each { |c| options += to_options(c) }
    return options
  end

  private
    def create_wrapper(name)
      full_name = @parent.present? ? "#{@parent}/#{name}" : name
      children = self.class.new(@categories, @hierarchy[name], full_name)
      category = @categories.find { |category| category.name == full_name }
      has_grandchild = children.any? { |child| child.children? }
      OpenStruct.new(
        id: category.try(:id),
        depth: category.try(:depth),
        name: name,
        full_name: full_name,
        children: children,
        children?: children.present?,
        real?: category.present?,
        virtual?: category.blank?,
        color?: category && category.color.present?,
        color: category.try(:color),
        text_color: category.try(:text_color),
        grandchild?: has_grandchild
      )
    end
end
