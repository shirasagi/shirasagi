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

  Pseudo = Struct.new(:id, :name) do
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

    alias_method :trailing_name, :name
  end

  ALL = Pseudo.new("-", I18n.t("ss.all"))
  NONE = Pseudo.new("na", I18n.t("gws/schedule/todo.category_not_assigined"))

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
    return self if root?
    self.class.all.where(site_id: self.site_id, name: name.split("/").first).first
  end

  def parent
    return nil if root?

    parent_name = name.split("/")[0..-2].join("/")
    self.class.all.where(site_id: self.site_id, name: parent_name).first
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

  private

  def color_required?
    false
  end

  def default_color
    nil
  end
end
