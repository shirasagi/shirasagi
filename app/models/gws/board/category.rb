class Gws::Board::Category
  include Gws::Model::Category
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  default_scope ->{ where(model: "gws/board/category").order_by(name: 1) }

  validate :validate_name_depth
  validate :validate_parent_name
  before_destroy :validate_children

  class << self
    def and_name_prefix(name_prefix)
      name_prefix = name_prefix[1..-1] if name_prefix.starts_with?('/')
      self.or({ name: name_prefix }, { name: /^#{Regexp.escape(name_prefix)}\// })
    end
  end

  private
    def color_required?
      false
    end

    def default_color
      nil
    end

    def validate_name_depth
      return if name.blank?
      errors.add :name, :too_deep, max: 2 if name.count('/') >= 2
    end

    def validate_parent_name
      return if name.blank?
      return if name.count('/') < 1

      errors.add :base, :not_found_parent unless self.class.where(name: File.dirname(name)).exists?
    end

    def validate_children
      if name.present? && self.class.where(name: /^#{Regexp.escape(name)}\//).exists?
        errors.add :base, :found_children
        return false
      end
      true
    end
end
