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

  # class << self
  #   def to_options
  #     self.all.map { |c| [c.name, c.id] }
  #   end
  # end

  def root?
    !name.include?("/")
  end

  def root
    return self if root?
    self.class.all.where(site_id: self.site_id, name: name.split("/").first).first
  end

  private

  def color_required?
    false
  end

  def default_color
    nil
  end
end
