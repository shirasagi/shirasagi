# coding: utf-8
class Cms::Role
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::Permission

  set_permission_name "cms_users"

  cattr_accessor(:permission_names) { [] }

  seqid :id
  field :name, type: String
  field :permission_level, type: Integer, default: 1
  field :permissions, type: SS::Extensions::Array
  permit_params :name, :permission_level, permissions: []

  validates :name, presence: true, length: { maximum: 80 }
  validates :permission_level, presence: true
  #validates :permissions, presence: true

  public
    def permission_level_options
      [%w(1 1), %w(2 2), %w(3 3)]
    end

    def allowed?(action, user, opts = {})
      return true if Sys::User.allowed?(action, user)
      super
    end

  class << self
    public
      def permission(name)
        self.permission_names << [name, name.to_s]
      end

      def allow(action, user, opts = {})
        return where({}) if Sys::User.allowed?(action, user)
        super
      end
  end
end
