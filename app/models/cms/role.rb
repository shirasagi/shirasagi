class Cms::Role
  include SS::Model::Role
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_roles", :edit

  class << self
    def to_csv(site, encode = nil)
      I18n.with_locale(I18n.default_locale) do
        CSV.generate do |data|
          data << header
          Cms::Role.site(site).each { |item| data << row(item) }
        end
      end
    end

    private

    def header
      headers = %w(id name permissions)
      headers.map { |e| t e }
    end

    def row(item)
      item.site ||= site

      row = [
        item.id,
        item.name,
        localized_permissions(item).join("\n")
      ]
      row
    end

    def localized_permissions(item)
      permissions = []
      item._module_permission_names.each do |mod, names|
        names.each do |name|
          next unless item.permissions.include? name.to_s
          permissions.push "[#{item.class.mod_name(mod)}]#{I18n.t("#{item.collection_name.to_s.singularize}.#{name}")}"
        end
      end
      permissions
    end
  end
end
