class Gws::Schedule::TodoCategory
  include Gws::Model::Category
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  default_scope -> {
    where(model: "gws/schedule/todo_category")
  }

  attr_accessor :in_basename, :in_parent_id

  field :depth_level, type: Integer

  before_validation :set_name, if: ->{ in_basename.present? }
  before_validation :set_depth_level
  validates :depth_level, presence: true
  validate :validate_basename, if: ->{ in_basename.present? }

  permit_params :in_basename, :in_parent_id

  class Pseudo
    include ActiveModel::Model

    attr_accessor :id, :name

    def real?
      false
    end

    def pseudo?
      true
    end

    def root?
      true
    end

    def hierarical_orders
      nil
    end

    def depth
      0
    end

    def persisted?
      true
    end

    alias trailing_name name
    alias depth_level depth
  end

  ALL = Pseudo.new(id: "-", name: I18n.t("ss.all"))
  NONE = Pseudo.new(id: "na", name: I18n.t("gws/schedule/todo.category_not_assigined"))

  # class << self
  #   def to_options
  #     self.all.map { |c| [c.name, c.id] }
  #   end
  # end

  def real?
    true
  end

  def pseudo?
    false
  end

  def root?
    !name.include?("/")
  end

  def root
    return self if new_record? || root?
    self.class.all.where(site_id: self.site_id, name: name.split("/").first).first
  end

  def parent
    return nil if new_record? || root?

    parent_name = name.split("/")[0..-2].join("/")
    self.class.all.where(site_id: self.site_id, name: parent_name).first
  end

  def basename
    return nil if new_record?
    ::File.basename(name)
  end

  def hierarical_orders
    names = name.split("/")

    hierarical_name = nil
    names.map do |n|
      if hierarical_name.nil?
        hierarical_name = n
      else
        hierarical_name += "/#{n}"
      end

      self.class.where(site_id: site_id, name: hierarical_name).first.try(:order) || 0
    end
  end

  def in_parent
    return if in_parent_id.blank?
    self.class.where(id: in_parent_id).first
  end

  private

  def color_required?
    false
  end

  def default_color
    nil
  end

  def set_name
    parts = []
    if in_parent_id.present?
      parent = self.class.where(id: in_parent_id).first
      parts << parent.name
    end
    parts << in_basename
    self.name = parts.map(&:presence).compact.join("/")
  end

  def set_depth_level
    self.depth_level = depth
  end

  def validate_basename
    return if in_basename.blank?

    if /[\\\/:*?"<>|]/.match?(in_basename)
      errors.add :in_basename, :invalid_chars_as_name
    end
  end
end
