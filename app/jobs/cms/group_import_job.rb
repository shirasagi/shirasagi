class Cms::GroupImportJob < Cms::ApplicationJob
  include Cms::CsvImportBase

  self.required_headers = %i[id name order ldap_dn activation_date expiration_date].map { |attr| Cms::Group.t(attr) }.freeze

  private

  def importer
    @importer ||= SS::Csv.draw(:import, context: self, model: Cms::Group) do |importer|
      define_importer_basic(importer)
      define_importer_ldap(importer)
      define_importer_contact(importer)
    end.create
  end

  def define_importer_basic(importer)
    importer.simple_column :id
    importer.simple_column :name
    importer.simple_column :order
    importer.simple_column :activation_date
    importer.simple_column :expiration_date
  end

  def define_importer_ldap(importer)
    importer.simple_column :ldap_dn
  end

  def define_importer_contact(importer)
    # importer.simple_column :ldap_dn
  end

  delegate :to_array, :from_label, to: SS::Csv::CsvImporter

  def value(row, key)
    key = Cms::Group.t(key) if key.is_a?(Symbol)
    row[key].try(:strip)
  end
end
