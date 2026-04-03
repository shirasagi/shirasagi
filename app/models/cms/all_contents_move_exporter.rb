class Cms::AllContentsMoveExporter
  include ActiveModel::Model

  attr_accessor :site

  CSV_HEADERS = %i[
    page_id name index_name filename layout order
    keywords description summary_html
    category parent_crumb_urls
    contact_state contact_group contact_group_contact contact_group_relation
    contact_group_name contact_charge contact_tel contact_fax contact_email
    contact_postal_code contact_address contact_link_url contact_link_name
    contact_sub_groups
    group_ids
  ].freeze

  def enum_csv(encoding: "UTF-8")
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      draw_columns(drawer)
    end
    drawer.enum(page_criteria, encoding: encoding, model: Cms::Page)
  end

  private

  def layout_cache
    @layout_cache ||= Cms::Layout.site(site).pluck(:id, :filename).to_h
  end

  def page_criteria
    Enumerator.new do |y|
      criteria = Cms::Page.site(site).where(master_id: nil)
      all_ids = criteria.pluck(:id)
      all_ids.each_slice(20) do |ids|
        criteria.in(id: ids).to_a.each { |page| y << page }
      end
    end
  end

  def draw_columns(drawer)
    draw_basic_columns(drawer)
    draw_meta_columns(drawer)
    draw_contact_columns(drawer)
    draw_group_columns(drawer)
  end

  def draw_basic_columns(drawer)
    drawer.column :page_id do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.page_id') }
      drawer.body { |item| item.id }
    end
    drawer.column :name do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.name') }
      drawer.body { |item| item.name }
    end
    drawer.column :index_name do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.index_name') }
      drawer.body { |item| item.index_name }
    end
    drawer.column :filename do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.filename') }
      drawer.body { |item| item.filename }
    end
    drawer.column :layout do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.layout') }
      drawer.body { |item| layout_cache[item.layout_id] }
    end
    drawer.column :order do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.order') }
      drawer.body { |item| item.order }
    end
  end

  def draw_meta_columns(drawer)
    drawer.column :keywords do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.keywords') }
      drawer.body { |item| item.try(:keywords).try(:join, ", ") }
    end
    drawer.column :description do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.description') }
      drawer.body { |item| item.try(:description) }
    end
    drawer.column :summary_html do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.summary_html') }
      drawer.body { |item| item.try(:summary_html) }
    end
    drawer.column :category do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.category') }
      drawer.body do |item|
        item.try(:categories).try(:pluck, :filename).try(:join, "\n")
      end
    end
    drawer.column :parent_crumb_urls do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.parent_crumb_urls') }
      drawer.body { |item| item.try(:parent_crumb_urls).try(:join, "\n") }
    end
  end

  def draw_contact_columns(drawer)
    draw_contact_group_columns(drawer)
    draw_contact_detail_columns(drawer)
  end

  def draw_contact_group_columns(drawer)
    drawer.column :contact_state do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_state') }
      drawer.body { |item| item.try(:contact_state) }
    end
    drawer.column :contact_group do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_group') }
      drawer.body { |item| item.try(:contact_group).try(:name) }
    end
    drawer.column :contact_group_contact do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_group_contact') }
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
    drawer.column :contact_group_relation do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_group_relation') }
      drawer.body { |item| item.try(:contact_group_relation) }
    end
    drawer.column :contact_group_name do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_group_name') }
      drawer.body { |item| item.try(:contact_group_name) }
    end
    drawer.column :contact_charge do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_charge') }
      drawer.body { |item| item.try(:contact_charge) }
    end
  end

  def draw_contact_detail_columns(drawer)
    drawer.column :contact_tel do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_tel') }
      drawer.body { |item| item.try(:contact_tel) }
    end
    drawer.column :contact_fax do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_fax') }
      drawer.body { |item| item.try(:contact_fax) }
    end
    drawer.column :contact_email do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_email') }
      drawer.body { |item| item.try(:contact_email) }
    end
    drawer.column :contact_postal_code do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_postal_code') }
      drawer.body { |item| item.try(:contact_postal_code) }
    end
    drawer.column :contact_address do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_address') }
      drawer.body { |item| item.try(:contact_address) }
    end
    drawer.column :contact_link_url do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_link_url') }
      drawer.body { |item| item.try(:contact_link_url) }
    end
    drawer.column :contact_link_name do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_link_name') }
      drawer.body { |item| item.try(:contact_link_name) }
    end
    drawer.column :contact_sub_groups do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.contact_sub_groups') }
      drawer.body { |item| item.try(:contact_sub_groups).try(:pluck, :name).try(:join, "\n") }
    end
  end

  def draw_group_columns(drawer)
    drawer.column :group_ids do
      drawer.head { I18n.t('cms.all_contents_moves.csv_headers.group_ids') }
      drawer.body { |item| item.try(:groups).try(:pluck, :name).try(:join, "\n") }
    end
  end
end
