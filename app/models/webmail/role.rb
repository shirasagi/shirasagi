class Webmail::Role
  include SS::Model::Role
  include Webmail::Referenceable
  # include Gws::Reference::Site
  include Webmail::Permission
  include Webmail::Addon::History
  # include Gws::Addon::Import::Role

  set_permission_name "webmail_roles", :edit

  attr_accessor :cur_user

  class << self
    def csv_headers
      %w(id name permissions)
    end

    def to_csv
      I18n.with_locale(I18n.default_locale) do
        CSV.generate do |data|
          data << csv_headers.map { |k| t k }
          criteria.each do |item|
            line = []
            line << item.id
            line << item.name
            line << item.localized_permissions.join("\n")
            data << line
          end
        end
      end
    end
  end

  def localized_permissions
    localized = []
    self._module_permission_names.each do |mod, names|
      names.each do |name|
        next unless self.permissions.include? name.to_s
        localized.push "[#{self.class.mod_name(mod)}]#{I18n.t("#{self.collection_name.to_s.singularize}.#{name}")}"
      end
    end
    localized
  end

  def normalized_permissions(localized)
    normalized = []
    self.class.module_permission_names(separator: true).each do |mod, names|
      names.each do |name|
        permission = "[#{self.class.mod_name(mod)}]#{I18n.t("#{self.collection_name.to_s.singularize}.#{name}")}"
        next unless localized.include? permission
        normalized << name.to_s
      end
    end
    normalized
  end
end
