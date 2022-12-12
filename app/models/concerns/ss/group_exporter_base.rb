module SS::GroupExporterBase
  extend ActiveSupport::Concern
  include ActiveModel::Model

  included do
    cattr_accessor :mode, instance_accessor: false
    attr_accessor :criteria
  end

  def enum_csv(options = {})
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      draw_basic(drawer)
      draw_ldap(drawer)
      draw_contact(drawer)
    end

    drawer.enum(criteria, options)
  end

  private

  def draw_basic(drawer)
    drawer.column :id
    drawer.column :name
    drawer.column :order
    drawer.column :activation_date
    drawer.column :expiration_date
    if self.class.mode == :sys
      drawer.column :gws_use, type: :label
    end
  end

  def draw_ldap(drawer)
    drawer.column :ldap_dn
  end

  CONTACT_GROUP_ATTRIBUTES = %i[
    main_state name contact_group_name contact_tel contact_fax contact_email contact_link_url contact_link_name
  ].freeze

  def draw_contact(drawer)
    count = max_contact_count > 5 ? max_contact_count : 5
    count.times.each do |i|
      CONTACT_GROUP_ATTRIBUTES.each do |attr|
        drawer.column "#{attr}#{i}" do
          drawer.head { "#{SS::Contact.t(attr)}#{i + 1}" }
          drawer.body { |item| export_contact_group_attr(item.contact_groups[i], attr) }
        end
      end
    end
  end

  def max_contact_count
    @max_contact_count ||= begin
      stages = [{ "$match" => criteria.selector }]
      stages << { "$project" => {
        contact_group_count: {
          "$cond" => {
            if: { "$isArray" => "$contact_groups" },
            then: { "$size" => "$contact_groups" },
            else: 0
          }
        }
      } }
      stages << { "$group" => { _id: "total", contact_group_count: { "$max" => "$contact_group_count" } } }
      results = criteria.klass.collection.aggregate(stages)
      results && results.first ? results.first["contact_group_count"] : 0
    end
  end

  def export_contact_group_attr(contact, attr)
    if attr == :main_state
      state = contact.try(:main_state)
      if state.present?
        I18n.t("contact.options.main_state.#{state}")
      end
    else
      contact.try(attr)
    end
  end
end
