class Chorg::ChangesetImportJob < Cms::ApplicationJob
  include Cms::CsvImportBase

  MAX_DESTINATION_COUNT = 20
  MAX_CONTACT_COUNT = Contact::Addon::Group::MAX_CONTACT_COUNT

  self.required_headers = proc do
    [
      I18n.t("chorg.import.changeset.type"),
      I18n.t("chorg.import.changeset.source"),
      I18n.t("chorg.import.changeset.nth_destination_name", dest_seq: 1),
    ]
  end

  def perform(*args)
    @revision = Chorg::Revision.site(site).find(args.shift)
    @revision.cur_site = site

    temp_file_id = args.shift
    @cur_file = SS::File.find(temp_file_id)

    Rails.logger.tagged(@revision.name, @cur_file.filename) do
      import_file
    end
  ensure
    if @cur_file && @cur_file.model == 'ss/temp_file'
      @cur_file.destroy
    end
  end

  private

  def import_file
    i = 0
    exception = nil
    self.class.each_csv(@cur_file) do |row|
      i += 1
      Rails.logger.tagged("#{i.to_fs(:delimited)}行目") do
        item = @revision.changesets.build
        importer.import_row(row, item)
        item.sources = nil if item.type == Chorg::Changeset::TYPE_ADD
        item.destinations = nil if item.type == Chorg::Changeset::TYPE_DELETE
        resolve_contact_ids(item)
        if item.save
          Rails.logger.info { "#{item.inspect}をインポートしました。" }
        else
          Rails.logger.warn { item.errors.full_messages.join("\n") }
        end
      rescue => e
        exception ||= e
        Rails.logger.error { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      end
    end
    raise exception if exception
  end

  def importer
    @importer ||= SS::Csv.draw(:import, context: self, model: Chorg::Changeset) do |importer|
      define_importer_basic(importer)
      define_importer_sources(importer)
      define_importer_destinations(importer)
    end.create
  end

  SOURCE_AND_DESTINATION_TYPES = [
    Chorg::Changeset::TYPE_MOVE, Chorg::Changeset::TYPE_UNIFY, Chorg::Changeset::TYPE_DIVISION
  ].freeze

  def resolve_contact_ids(item)
    return unless SOURCE_AND_DESTINATION_TYPES.include?(item.type)
    return if item.sources.blank? || item.destinations.blank?

    source_groups = item.sources.map do |source|
      source_group_name = source[:name]
      next if source_group_name.blank?

      name_group_map[source_group_name]
    end
    source_groups.compact!
    source_groups.sort! do |lhs, rhs|
      diff = lhs.order <=> rhs.order
      next diff if diff != 0

      lhs.name <=> rhs.name
    end

    item.destinations.each do |destination|
      contact_groups = destination[:contact_groups]
      next if contact_groups.blank?

      contact_groups.each do |contact_group|
        contact_id_name = contact_group[:name]
        next if contact_id_name.blank?

        source_contact = find_source_contact(source_groups, contact_id_name)
        if source_contact
          contact_group[:_id] = source_contact.id.to_s
          break
        end
      end
    end
  end

  def find_source_contact(groups, contact_id_name)
    groups.each do |group|
      contact = group.contact_groups.where(name: contact_id_name).first
      return contact if contact
    end

    nil
  end

  def define_importer_basic(importer)
    importer.simple_column :type, name: I18n.t("chorg.import.changeset.type") do |row, item, head, value|
      item.type = from_label(value, type_options)
    end
  end

  def define_importer_sources(importer)
    importer.simple_column :source, name: I18n.t("chorg.import.changeset.source") do |row, item, head, value|
      next if value.blank?

      names = to_array(value)
      groups = names.map do |name|
        group = name_group_map[name]
        if group.blank?
          Rails.logger.warn { "#{name}: グループが見つかりません。" }
        end
        group
      end
      groups.compact!
      item.sources = groups.map { |group| { id: group.id, name: group.name }.with_indifferent_access }
    end
  end

  def define_importer_destinations(importer)
    1.upto(MAX_DESTINATION_COUNT).each do |sequence|
      define_importer_destination_basic(importer, sequence)
      define_importer_destination_ldap(importer, sequence)
      define_importer_destination_contact(importer, sequence)
    end
  end

  def define_importer_destination_basic(importer, sequence)
    index = sequence - 1

    I18n.t("chorg.import.changeset.nth_destination_name", dest_seq: sequence).tap do |name|
      importer.simple_column "destination#{index}", name: name do |row, item, head, value|
        update_destination_attr(item, index, :name, value)
      end
    end
    I18n.t("chorg.import.changeset.nth_destination_order", dest_seq: sequence).tap do |name|
      importer.simple_column "order#{index}", name: name do |row, item, head, value|
        update_destination_attr(item, index, :order, value)
      end
    end
  end

  def define_importer_destination_ldap(importer, sequence)
    index = sequence - 1

    I18n.t("chorg.import.changeset.nth_destination_ldap_dn", dest_seq: sequence).tap do |name|
      importer.simple_column "ldap_dn#{index}", name: name do |row, item, head, value|
        update_destination_attr(item, index, :ldap_dn, value)
      end
    end
  end

  def define_importer_destination_contact(importer, dest_seq)
    dest_index = dest_seq - 1

    1.upto(MAX_CONTACT_COUNT).each do |contact_seq|
      contact_index = contact_seq - 1

      key = "chorg.import.changeset.nth_destination_contact_main_state"
      name = I18n.t(key, dest_seq: dest_seq, contact_seq: contact_seq)
      importer.simple_column "contact_main_state_#{dest_index}_#{contact_index}", name: name do |row, item, head, value|
        main_state = from_label(value, main_state_options)
        update_contact_attr(item, dest_index, contact_index, :main_state, main_state)
      end

      Chorg::ChangesetExporter::DESTINATION_CONTACT_ATTRS.each do |attr|
        key = "chorg.import.changeset.nth_destination_contact_#{attr}"
        name = I18n.t(key, dest_seq: dest_seq, contact_seq: contact_seq)
        importer.simple_column "contact_#{attr}_#{dest_index}_#{contact_index}", name: name do |row, item, head, value|
          update_contact_attr(item, dest_index, contact_index, attr, value)
        end
      end
    end
  end

  delegate :to_array, :from_label, to: SS::Csv::CsvImporter

  def type_options
    @type_options ||= begin
      Chorg::Changeset::TYPES.map do |v|
        [ I18n.t("chorg.options.changeset_type.#{v}"), v ]
      end
    end
  end

  def main_state_options
    @main_state_options ||= begin
      %w(main).map do |v|
        [ I18n.t("contact.options.main_state.#{v}"), v ]
      end
    end
  end

  def all_groups
    @all_groups ||= Cms::Group.all.site(site).to_a
  end

  def name_group_map
    @name_group_map ||= all_groups.index_by(&:name)
  end

  def update_destination_attr(item, index, attr, value)
    destinations = item.destinations
    if destinations.nil?
      destinations = []
    end
    destination = destinations[index]
    if destination.nil?
      destination = {}.with_indifferent_access
    end
    destination[attr] = value
    destinations[index] = destination
    item.destinations = destinations
  end

  def update_contact_attr(item, dest_index, contact_index, attr, value)
    destinations = item.destinations
    if destinations.nil?
      destinations = []
    end

    destination = destinations[dest_index]
    if destination.nil?
      destination = {}.with_indifferent_access
    end

    contact_groups = destination[:contact_groups]
    if contact_groups.nil?
      contact_groups = []
    end

    contact_group = contact_groups[contact_index]
    if contact_group.nil?
      contact_group = {}.with_indifferent_access
    end

    contact_group[attr] = value
    contact_groups[contact_index] = contact_group
    destination[:contact_groups] = contact_groups
    destinations[dest_index] = destination
    item.destinations = destinations
  end
end
