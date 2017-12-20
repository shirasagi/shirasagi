class Cms::Role
  include SS::Model::Role
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_roles", :edit

  field :permission_level, type: Integer, default: 1

  permit_params :permission_level

  validates :permission_level, presence: true

  def permission_level_options
    [%w(1 1), %w(2 2), %w(3 3)]
  end

  class << self
    def to_csv(site, encode = nil)
      CSV.generate do |data|
        data << header
        Cms::Role.site(site).each { |item| data << row(item) }
      end
    end

    private

    def header
      %w(id created updated name permissions site_id permission_level).map { |e| t e }
    end

    def row(item)
      item.site ||= site

      [
        item.id,
        item.created,
        item.updated,
        item.name,
        localized_permissions(item).join("\n"),
        item.site_id,
        item.permission_level
      ]
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
