module SS::GroupImportBase
  extend ActiveSupport::Concern
  include Cms::CsvImportBase
  include SS::ZipFileImport

  REQUIRED_FIELDS = %i[id name order ldap_dn activation_date expiration_date].freeze

  included do
    cattr_accessor :mode, instance_accessor: false
    cattr_accessor :model, instance_accessor: false
    define_callbacks :import_row

    self.required_headers = proc do
      REQUIRED_FIELDS.map { |attr| self.model.t(attr) }.freeze
    end

    set_callback :import_row, :before do
      @contact_groups = @item.contact_groups.to_a.dup
    end
    set_callback :import_row, :after do
      @item.contact_groups = @contact_groups.compact
    ensure
      @contact_groups = nil
    end
  end

  private

  def import_file
    i = 0
    self.class.each_csv(@cur_file) do |row|
      i += 1
      Rails.logger.tagged("#{(i + 1).to_s(:delimited)}行目") do
        @item = find_or_initialize_item(row)
        next unless @item

        run_callbacks :import_row do
          importer.import_row(row, @item)
        end
        if @item.save
          Rails.logger.info("#{@item.name}(#{@item.id})をインポートしました。")
        else
          Rails.logger.warn(@item.errors.full_messages.join("\n"))
        end
      end
    end

    Rails.logger.info("#{i.to_s(:delimited)}件のグループをインポートしました。")
  end

  def importer
    @importer ||= SS::Csv.draw(:import, context: self, model: self.class.model) do |importer|
      define_importers(importer)
    end.create
  end

  def define_importers(importer)
    define_importer_basic(importer)
    define_importer_ldap(importer)
    define_importer_contact(importer)
  end

  def define_importer_basic(importer)
    importer.simple_column :name
    importer.simple_column :order
    importer.simple_column :activation_date
    importer.simple_column :expiration_date
    if self.class.mode == :sys
      importer.simple_column :gws_use do |row, item, head, value|
        name = row[self.class.model.t(:name)]
        if name.present? && !name.include?("/") # organization?
          item.gws_use = from_label(value, item.gws_use_options)
        else
          item.gws_use = nil
        end
      end
    end
  end

  def define_importer_ldap(importer)
    importer.simple_column :ldap_dn
  end

  CONTACT_ATTRIBUTES = %i[
    main_state name contact_group_name contact_tel contact_fax contact_email contact_link_url contact_link_name
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
    key = self.class.model.t(key) if key.is_a?(Symbol)
    row[key].try(:strip)
  end

  def main_state_options
    %w(main).map do |v|
      [ I18n.t("contact.options.main_state.#{v}"), v ]
    end
  end
end
