class Sys::Role
  include SS::Model::Role
  include Sys::Permission

  set_permission_name "sys_roles", :edit

  field :permissions, type: SS::Extensions::Words, overwrite: true

  validates :permissions, presence: true

  def privileged?
    permissions.any? { |perm| self.class.privileged_permission_names.include?(perm) }
  end

  def general?
    !privileged?
  end

  class << self
    GENERAL_PERMISSION_NAMES = %w(use_cms use_gws use_webmail).freeze

    def privileged_permission_names
      @privileged_permission_names ||= permission_names - general_permission_names
    end

    def general_permission_names
      GENERAL_PERMISSION_NAMES
    end

    def and_general
      self.nin(permissions: privileged_permission_names)
    end
  end
end
