class Cms::AllContentsMovesExporter < Cms::PageExporter
  include ActiveModel::Model

  def initialize(site:, criteria: nil)
    super(mode: "all", site: site, criteria: criteria || new_enumerator)
  end

  def enum_csv(options = {})
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      draw_basic(drawer)
      draw_meta(drawer)
      draw_contact(drawer)
      draw_groups(drawer)
    end

    drawer.enum(criteria, options.merge(model: Cms::Page, encoding: options[:encoding] || "Shift_JIS"))
  end

  private

  def new_enumerator
    Enumerator.new do |y|
      each_page do |page|
        y << page
      end
    end
  end

  def each_page(&block)
    page_criteria = Cms::Page.site(site).all
    all_page_ids = page_criteria.pluck(:id)
    all_page_ids.each_slice(20) do |page_ids|
      page_criteria.in(id: page_ids).to_a.each(&block)
    end
  end

  def draw_basic(drawer)
    drawer.column :page_id do
      drawer.head { I18n.t("all_content.page_id") }
      drawer.body { |item| item.id }
    end
    drawer.column :name
    drawer.column :filename do
      drawer.head { I18n.t("cms.all_contents_moves.destination_filename") }
      drawer.body { |item| item.filename }
    end
    drawer.column :index_name
    drawer.column :layout do
      drawer.head { I18n.t("mongoid.attributes.cms/reference/layout.layout") }
      drawer.body { |item| item.layout.try(:name) }
    end
    drawer.column :order
  end

  def draw_meta(drawer)
    drawer.column :keywords
    drawer.column :description
    drawer.column :summary_html
  end

  def draw_contact(drawer)
    drawer.column :contact_state, type: :label
    drawer.column :contact_group do
      drawer.head { I18n.t("mongoid.attributes.contact/addon/group.contact_group") }
      drawer.body { |item| item.try(:contact_group).try(:name) }
    end
    drawer.column :contact_group_contact do
      drawer.head { I18n.t("mongoid.attributes.cms/model/page.contact_group_contact") }
      drawer.body do |item|
        contact_id = item.try(:contact_group_contact_id)
        next if contact_id.blank?

        contact_group = item.try(:contact_group)
        next if contact_group.blank?

        contact = contact_group.contact_groups.where(id: contact_id).first
        next if contact.blank?

        contact.name.presence || contact.id.to_s
      end
    end
    drawer.column :contact_group_relation, type: :label
    drawer.column :contact_group_name do
      drawer.head { I18n.t("mongoid.attributes.cms/model/page.contact_group_name") }
      drawer.body { |item| item.try(:contact_group_name) }
    end
    drawer.column :contact_charge
    drawer.column :contact_tel
    drawer.column :contact_fax
    drawer.column :contact_email
    drawer.column :contact_postal_code
    drawer.column :contact_address
    drawer.column :contact_link_url
    drawer.column :contact_link_name
  end

  def draw_groups(drawer)
    drawer.column :groups do
      drawer.head { I18n.t("mongoid.attributes.cms/addon/group_permission.groups") }
      drawer.body { |item| item.groups.pluck(:name).join("\n") }
    end
  end
end
