class Cms::GroupExporter
  include ActiveModel::Model

  attr_accessor :site, :criteria

  def enum_csv(options = {})
    # has_form = options[:form].present?
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
  end

  def draw_ldap(drawer)
    drawer.column :ldap_dn
  end

  def draw_contact(drawer)
    count = max_contact_count > 5 ? max_contact_count : 5
    count.times.each do |i|
      drawer.column "main_state#{i}" do
        drawer.head { "#{SS::Contact.t(:main_state)}#{i + 1}" }
        drawer.body do |item|
          state = item.contact_groups[i].try(:main_state)
          if state.present?
            I18n.t("contact.options.main_state.#{state}")
          end
        end
      end
      drawer.column "contact_group_name#{i}" do
        drawer.head { "#{SS::Contact.t(:contact_group_name)}#{i + 1}" }
        drawer.body { |item| item.contact_groups[i].try(:contact_group_name) }
      end
      drawer.column "contact_tel#{i}" do
        drawer.head { "#{SS::Contact.t(:contact_tel)}#{i + 1}" }
        drawer.body { |item| item.contact_groups[i].try(:contact_tel) }
      end
      drawer.column "contact_fax#{i}" do
        drawer.head { "#{SS::Contact.t(:contact_fax)}#{i + 1}" }
        drawer.body { |item| item.contact_groups[i].try(:contact_fax) }
      end
      drawer.column "contact_email#{i}" do
        drawer.head { "#{SS::Contact.t(:contact_email)}#{i + 1}" }
        drawer.body { |item| item.contact_groups[i].try(:contact_email) }
      end
      drawer.column "contact_link_url#{i}" do
        drawer.head { "#{SS::Contact.t(:contact_link_url)}#{i + 1}" }
        drawer.body { |item| item.contact_groups[i].try(:contact_link_url) }
      end
      drawer.column "contact_link_name#{i}" do
        drawer.head { "#{SS::Contact.t(:contact_link_name)}#{i + 1}" }
        drawer.body { |item| item.contact_groups[i].try(:contact_link_name) }
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
end
