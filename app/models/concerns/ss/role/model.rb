module SS::Role::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User

  included do
    cattr_accessor(:_permission_names) { [] }
    cattr_accessor(:_module_permission_names) { {} }

    seqid :id
    field :name, type: String
    field :permissions, type: SS::Extensions::Array

    permit_params :name, permissions: [] #TODO:

    validates :name, presence: true, length: { maximum: 80 }

    class << self
      def permission(name, opts = {})
        module_name = opts[:module_name] || name.to_s.sub(/^[a-z]+_(private_|other_)?(.*)?_.*/, '\\2')
        module_name = :"#{module_name}"

        self._permission_names << name.to_s
        self._module_permission_names[module_name] ||= []
        self._module_permission_names[module_name] << name
      end

      def permission_names
        _permission_names.sort
      end

      def module_permission_names
        _module_permission_names.sort_by { |k, v| k }.map do |k, v|
          [k, v.sort_by { |name| I18n.t("cms_role.#{name}") } ]
        end
      end
    end
  end
end
