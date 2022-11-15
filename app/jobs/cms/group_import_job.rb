class Cms::GroupImportJob < Cms::ApplicationJob
  include Cms::CsvImportBase
  include SS::ZipFileImport

  self.required_headers = %i[id name order ldap_dn activation_date expiration_date].map { |attr| Cms::Group.t(attr) }.freeze

  private

  def import_file
    i = 0
    self.class.each_csv(@cur_file) do |row|
      i += 1
      Rails.logger.tagged("#{(i + 1).to_s(:delimited)}行目") do
        id = value(row, :id)
        item = Cms::Group.site(site).where(id: id).first if id.present?
        item ||= Cms::Group.new
        item.cur_site = site
        @contact_groups = item.contact_groups.to_a.dup

        importer.import_row(row, item)
        item.contact_groups = @contact_groups.compact
        if item.save
          Rails.logger.info("#{item.name}(#{item.id})をインポートしました。")
        else
          Rails.logger.warn(item.errors.full_messages.join("\n"))
        end
      end
    end

    Rails.logger.info("#{i.to_s(:delimited)}件のグループをインポートしました。")
  end

  def importer
    @importer ||= SS::Csv.draw(:import, context: self, model: Cms::Group) do |importer|
      define_importer_basic(importer)
      define_importer_ldap(importer)
      define_importer_contact(importer)
    end.create
  end

  def define_importer_basic(importer)
    # importer.simple_column :id
    importer.simple_column :name
    importer.simple_column :order
    importer.simple_column :activation_date
    importer.simple_column :expiration_date
  end

  def define_importer_ldap(importer)
    importer.simple_column :ldap_dn
  end

  CONTACT_ATTRIBUTES = %i[
    main_state contact_group_name contact_tel contact_fax contact_email contact_link_url contact_link_name
  ].freeze

  def define_importer_contact(importer)
    Contact::Addon::Group::MAX_CONTACT_COUNT.times.each do |i|
      CONTACT_ATTRIBUTES.each do |attr|
        importer.simple_column "#{attr}#{i}", name: "#{SS::Contact.t(attr)}#{i + 1}" do |row, item, head, value|
          if value.present? && attr == :main_state
            value = from_label(value, main_state_options)
          end
          if value.present?
            @contact_groups[i] ||= SS::Contact.new
            @contact_groups[i].send("#{attr}=", value)
          else
            # value is blank
            if @contact_groups[i]
              @contact_groups[i].send("#{attr}=", nil)
            end
          end
        end
      end
    end
  end

  delegate :to_array, :from_label, to: SS::Csv::CsvImporter

  def value(row, key)
    key = Cms::Group.t(key) if key.is_a?(Symbol)
    row[key].try(:strip)
  end

  def main_state_options
    %w(main).map do |v|
      [ I18n.t("contact.options.main_state.#{v}"), v ]
    end
  end
end
