module SS::Model::Role
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User

  included do
    cattr_accessor(:_permission_names) { [] }
    cattr_accessor(:_module_permission_names) { {} }

    seqid :id
    field :name, type: String
    field :permissions, type: SS::Extensions::Words

    permit_params :name, permissions: [] #TODO:

    validates :name, presence: true, length: { maximum: 80 }

    scope :search, ->(params) {
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    }
  end

  module ClassMethods
    def mod_name(mod)
      I18n.t("modules.#{mod}")
    end

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
      scope = collection_name.to_s.singularize
      _module_permission_names.sort_by { |k, v| k }.map do |k, v|
        [k, v.sort_by { |name| I18n.t("#{scope}.#{name}") } ]
      end
    end
  end
end
