class Chorg::ChangesetExporter
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :revision

  MIN_DESTINATION_COUNT = 3
  MIN_CONTACT_COUNT = 1

  DESTINATION_CONTACT_ATTRS = %i[
    name contact_group_name contact_tel contact_fax contact_email contact_link_url contact_link_name
  ].freeze

  class << self
    def samples
      items = SS.config.chorg.changeset_sample_csv2
      return [] if items.blank?

      items.map do |item|
        item = item.symbolize_keys
        if item[:sources].present?
          item[:sources] = item[:sources].map { |source| source.symbolize_keys }
        end
        if item[:destinations].present?
          item[:destinations] = item[:destinations].map do |destination|
            destination = destination.symbolize_keys
            if destination[:contact_groups].present?
              destination[:contact_groups] = destination[:contact_groups].map { |contact_group| contact_group.symbolize_keys }
            end
            destination
          end
        end

        Mongoid::Factory.build(Chorg::Changeset, item)
      end
    end
  end

  def enum_csv(options = {})
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      draw_basic(drawer)
      draw_sources(drawer)
      draw_destinations(drawer)
    end

    @export_sets = revision.changesets.sort(&Chorg::Changeset.method(:comparer))
    options = options.merge(model: Chorg::Changeset)
    drawer.enum(@export_sets, options)
  end

  def enum_sample_csv(options = {})
    @max_destination_count = MIN_DESTINATION_COUNT
    @max_contact_count = MIN_CONTACT_COUNT

    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      draw_basic(drawer)
      draw_sources(drawer)
      draw_destinations(drawer)
    end

    @export_sets = self.class.samples
    options = options.merge(model: Chorg::Changeset)
    drawer.enum(@export_sets, options)
  end

  private

  def max_destination_count
    return @max_destination_count if instance_variable_defined?(:@max_destination_count)

    max = revision.changesets.map { |item| item.destinations.try(:length) || 0 }.max
    max ||= 0
    max = MIN_DESTINATION_COUNT if max < MIN_DESTINATION_COUNT

    @max_destination_count = max
  end

  def max_contact_count
    return @max_contact_count if instance_variable_defined?(:@max_contact_count)

    counts = revision.changesets.map do |item|
      next if item.destinations.blank?
      item.destinations.map { |destination| destination[:contact_groups].try(:length) }
    end
    counts.flatten!
    counts.compact!
    max = counts.max
    max ||= 0

    max = MIN_CONTACT_COUNT if max < MIN_CONTACT_COUNT

    @max_contact_count = max
  end

  def destination_attr(destinations, index, attr)
    destination = destinations[index] if destinations
    destination[attr] if destination
  end

  def contact_attr(destinations, destination_index, contact_index, attr)
    destination =  destinations[destination_index] if destinations
    contact_groups = destination[:contact_groups] if destination
    contact_group = contact_groups[contact_index] if contact_groups
    contact_group[attr] if contact_group
  end

  def draw_basic(drawer)
    drawer.column :type do
      drawer.head { I18n.t("chorg.import.changeset.type") }
      drawer.body { |item| I18n.t("chorg.options.changeset_type.#{item.type}") }
    end
  end

  # rubocop:disable Rails/Pluck
  def draw_sources(drawer)
    drawer.column :source do
      drawer.head { I18n.t("chorg.import.changeset.source") }
      drawer.body do |item|
        if item.sources.present?
          item.sources.map { |source| source[:name] }.join("\n")
        end
      end
    end
  end
  # rubocop:enable Rails/Pluck

  def draw_destinations(drawer)
    1.upto(max_destination_count).each do |sequence|
      draw_destination_basic(drawer, sequence)
      draw_destination_ldap(drawer, sequence)
      draw_destination_contact(drawer, sequence)
    end
  end

  def draw_destination_basic(drawer, sequence)
    index = sequence - 1

    drawer.column "destination#{index}" do
      drawer.head { I18n.t("chorg.import.changeset.nth_destination_name", dest_seq: sequence) }
      drawer.body { |item| destination_attr(item.destinations, index, :name) }
    end
    drawer.column "order#{index}" do
      drawer.head { I18n.t("chorg.import.changeset.nth_destination_order", dest_seq: sequence) }
      drawer.body { |item| destination_attr(item.destinations, index, :order) }
    end
  end

  def draw_destination_ldap(drawer, sequence)
    index = sequence - 1

    drawer.column "ldap_dn#{index}" do
      drawer.head { I18n.t("chorg.import.changeset.nth_destination_ldap_dn", dest_seq: sequence) }
      drawer.body { |item| destination_attr(item.destinations, index, :ldap_dn) }
    end
  end

  def draw_destination_contact(drawer, dest_seq)
    dest_index = dest_seq - 1

    1.upto(max_contact_count).each do |contact_seq|
      contact_index = contact_seq - 1

      drawer.column "contact_main_state_#{dest_index}_#{contact_index}" do
        drawer.head do
          I18n.t("chorg.import.changeset.nth_destination_contact_main_state", dest_seq: dest_seq, contact_seq: contact_seq)
        end
        drawer.body do |item|
          main_state = contact_attr(item.destinations, dest_index, contact_index, :main_state)
          I18n.t("contact.options.main_state.#{main_state}") if main_state.present?
        end
      end

      DESTINATION_CONTACT_ATTRS.each do |attr|
        drawer.column "contact_#{attr}_#{dest_index}_#{contact_index}" do
          drawer.head do
            I18n.t("chorg.import.changeset.nth_destination_contact_#{attr}", dest_seq: dest_seq, contact_seq: contact_seq)
          end
          drawer.body { |item| contact_attr(item.destinations, dest_index, contact_index, attr) }
        end
      end
    end
  end
end
