class Chorg::Revision
  include Chorg::Model::Revision
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name 'chorg_revisions', :edit

  has_many :changesets, class_name: 'Chorg::Changeset', dependent: :destroy
  has_many :tasks, class_name: 'Chorg::Task', dependent: :destroy
  belongs_to_file :content_csv_file

  def changesets_to_csv
    CSV.generate do |data|
      data << %w(
        id type source destination order
        contact_tel contact_fax contact_email contact_link_url contact_link_name
        ldap_dn
      ).map { |k| I18n.t("chorg.views.import_changesets.#{k}") }

      type_order = Chorg::Changeset::TYPES.each_with_index.map { |type, i| [type, i] }.to_h
      changesets.sort { |a, b| type_order[a.type] <=> type_order[b.type] }.each do |item|
        case item.type
        when Chorg::Changeset::TYPE_UNIFY

          # N sources, 1 destination
          destination = item.destinations.to_a.first || {}
          item.sources.to_a.each do |source|
            data << changeset_csv_line(item, source, destination)
          end
        when Chorg::Changeset::TYPE_DIVISION

          # 1 source, N destinations
          source = item.sources.to_a.first || {}
          item.destinations.to_a.each do |destination|
            data << changeset_csv_line(item, source, destination)
          end
        else

          # 1 source, 1 destination
          source = item.sources.to_a.first || {}
          destination = item.destinations.to_a.first || {}
          data << changeset_csv_line(item, source, destination)
        end
      end
    end
  end

  private

  def changeset_csv_line(item, source, destination)
    line = []
    line << item.id
    line << I18n.t("chorg.views.revisions/edit.#{item.type}")
    line << source["name"]
    line << destination["name"]
    line << destination["order"]
    line << destination["contact_tel"]
    line << destination["contact_fax"]
    line << destination["contact_email"]
    line << destination["contact_link_url"]
    line << destination["contact_link_name"]
    line << destination["ldap_dn"]
    line
  end
end
