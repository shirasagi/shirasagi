class Sys::Role
  include SS::Model::Role
  include Sys::Permission

  set_permission_name "sys_roles", :edit

  field :permissions, type: SS::Extensions::Words, overwrite: true

  validates :permissions, presence: true

  def general?
    (permissions - self.class.general_permission_names).select(&:present?).blank?
  end

  class << self
    def general_permission_names
      %w(use_cms use_gws use_webmail)
    end

    def and_general
      self.nin(permissions: (permission_names - general_permission_names))
    end
  end
end
