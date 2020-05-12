require "csv"

module Article::Export
  extend ActiveSupport::Concern

  def category_name_tree
    id_list = categories.where(route: /^category\//).pluck(:id)

    ct_list = []
    id_list.each do |id|
      name_list = []
      filename_str = []
      filename_array = Cms::Node.where(_id: id).pluck(:filename).first.split(/\//)
      filename_array.each do |filename|
        filename_str << filename
        node = Cms::Node.site(site).where(filename: filename_str.join("/")).first
        name_list << node.name if node
      end
      ct_list << name_list.join("/")
    end
    ct_list.sort
  end

  module ClassMethods
    def enum_csv(options = {})
      has_form = options[:form].present?
      drawer = SS::Csv.draw(:export, context: self) do |drawer|
        draw_basic(drawer)
        draw_meta(drawer)
        if has_form
          draw_form(drawer, options[:form])
        else
          draw_body(drawer)
        end
        draw_category(drawer)
        draw_event(drawer)
        draw_related_pages(drawer)
        draw_crumb(drawer)
        draw_contact(drawer)
        draw_released(drawer)
        draw_groups(drawer)
        draw_state(drawer)
      end

      drawer.enum(self.all, options)
    end

    private

    def draw_basic(drawer)
      drawer.column :filename do
        drawer.body { |item| item.basename }
      end
      drawer.column :name
      drawer.column :index_name
      drawer.column :layout do
        drawer.body { |item| Cms::Layout.where(id: item.layout_id).pluck(:name).first }
      end
      drawer.column :body_layout_id do
        drawer.body { |item| Cms::BodyLayout.where(id: item.body_layout_id).pluck(:name).first }
      end
      drawer.column :form_id do
        drawer.body { |item| item.form.try(:name) }
      end
      drawer.column :order
      drawer.column :redirect_link
    end

    def draw_meta(drawer)
      drawer.column :keywords
      drawer.column :description
      drawer.column :summary_html
    end

    def draw_body(drawer)
      drawer.column :html
      drawer.column :body_part do
        drawer.body { |item| item.body_parts.map { |body| body.gsub("\t", '    ') }.join("\t") }
      end
    end

    def draw_category(drawer)
      drawer.column :categories do
        drawer.body { |item| item.category_name_tree.join("\n") }
      end
    end

    def draw_event(drawer)
      drawer.column :event_name
      drawer.column :event_dates
      drawer.column :event_deadline
    end

    def draw_related_pages(drawer)
      drawer.column :related_pages do
        drawer.body { |item| item.related_pages.pluck(:filename).join("\n") }
      end
      drawer.column :related_page_sort, type: :label do
        drawer.head { "#{Article::Page.t(:related_pages)}#{Article::Page.t(:related_page_sort)}" }
      end
    end

    def draw_crumb(drawer)
      drawer.column :parent_crumb do
        drawer.body { |item| item.parent_crumb_urls }
      end
    end

    def draw_contact(drawer)
      drawer.column :contact_state, type: :label
      drawer.column :contact_group do
        drawer.body { |item| item.contact_group.try(:name) }
      end
      drawer.column :contact_charge
      drawer.column :contact_tel
      drawer.column :contact_fax
      drawer.column :contact_email
      drawer.column :contact_link_url
      drawer.column :contact_link_name
    end

    def draw_released(drawer)
      drawer.column :released
      drawer.column :release_date
      drawer.column :close_date
    end

    def draw_groups(drawer)
      drawer.column :groups do
        drawer.body { |item| item.groups.pluck(:name).join("\n") }
      end
      drawer.column :permission_level
    end

    def draw_state(drawer)
      drawer.column :state, type: :label
    end

    def draw_form(drawer, form)
      return if form.blank?

      # currently entry type form is not supported
      return if !form.sub_type_static?

      form.columns.order_by(order: 1, name: 1).each do |column|
        draw_column(drawer, form, column)
      end
    end

    def draw_column(drawer, form, column)
      value_type = column.class.value_type

      draw_column_common(drawer, form, column, value_type)

      draw_method = "draw_column_#{value_type.name.demodulize.underscore}"
      if respond_to?(draw_method, true)
        send(draw_method, drawer, form, column, value_type)
      end
    end

    def draw_column_common(drawer, form, column, value_type)
      # drawer.column "#{form.id}/#{column.id}/order" do
      #   drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:order)}" }
      #   drawer.body { |item| find_column_value(item, form, column).try(:order) }
      # end
      drawer.column "#{form.id}/#{column.id}/alignment" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:alignment)}" }
        drawer.body do |item|
          find_column_value(item, form, column).try do |v|
            I18n.t("cms.options.alignment.#{v.alignment.presence || "flow"}")
          end
        end
      end
    end

    def draw_column_check_box(drawer, form, column, value_type)
      drawer.column "#{form.id}/#{column.id}/values" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:values)}" }
        drawer.body { |item| find_column_value(item, form, column).try { |v| v.values.join(", ") } }
      end
    end

    def draw_column_date_field(drawer, form, column, value_type)
      drawer.column "#{form.id}/#{column.id}/date" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:date)}" }
        drawer.body { |item| find_column_value(item, form, column).try(:date) }
      end
    end

    def draw_column_file_upload(drawer, form, column, value_type)
      case column.file_type
      when 'attachment'
        drawer.column "#{form.id}/#{column.id}/file_label" do
          drawer.head { "#{form.name}/#{column.name}/#{I18n.t("cms.column_file_upload.attachment.file_label")}" }
          drawer.body { |item| find_column_value(item, form, column).try(:file_label) }
        end
      when 'video'
        drawer.column "#{form.id}/#{column.id}/text" do
          drawer.head { "#{form.name}/#{column.name}/#{I18n.t("cms.column_file_upload.video.text")}" }
          drawer.body { |item| find_column_value(item, form, column).try(:text) }
        end
      when 'banner'
        drawer.column "#{form.id}/#{column.id}/link_url" do
          drawer.head { "#{form.name}/#{column.name}/#{I18n.t("cms.column_file_upload.banner.link_url")}" }
          drawer.body { |item| find_column_value(item, form, column).try(:link_url) }
        end
        drawer.column "#{form.id}/#{column.id}/file_label" do
          drawer.head { "#{form.name}/#{column.name}/#{I18n.t("cms.column_file_upload.banner.file_label")}" }
          drawer.body { |item| find_column_value(item, form, column).try(:file_label) }
        end
      else # 'image'
        drawer.column "#{form.id}/#{column.id}/file_label" do
          drawer.head { "#{form.name}/#{column.name}/#{I18n.t("cms.column_file_upload.image.file_label")}" }
          drawer.body { |item| find_column_value(item, form, column).try(:file_label) }
        end
        drawer.column "#{form.id}/#{column.id}/image_html_type" do
          drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:image_html_type)}" }
          drawer.body do |item|
            find_column_value(item, form, column).try do |v|
              v.image_html_type ? I18n.t("cms.options.column_image_html_type.#{v.image_html_type}") : nil
            end
          end
        end
      end
    end

    def draw_column_free(drawer, form, column, value_type)
      drawer.column "#{form.id}/#{column.id}/value" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:value)}" }
        drawer.body { |item| find_column_value(item, form, column).try(:value) }
      end
    end

    def draw_column_headline(drawer, form, column, value_type)
      drawer.column "#{form.id}/#{column.id}/head" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:head)}" }
        drawer.body { |item| find_column_value(item, form, column).try { |v| v.head } }
      end
      drawer.column "#{form.id}/#{column.id}/text" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:text)}" }
        drawer.body { |item| find_column_value(item, form, column).try(:text) }
      end
    end

    def draw_column_list(drawer, form, column, value_type)
      drawer.column "#{form.id}/#{column.id}/lists" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:lists)}" }
        drawer.body { |item| find_column_value(item, form, column).try { |v| v.lists.join("\n") } }
      end
    end

    alias draw_column_radio_button draw_column_free

    alias draw_column_select draw_column_free

    alias draw_column_table draw_column_free

    alias draw_column_text_area draw_column_free

    alias draw_column_text_field draw_column_free

    alias draw_column_url_field draw_column_free

    def draw_column_url_field2(drawer, form, column, value_type)
      drawer.column "#{form.id}/#{column.id}/link_url" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:link_url)}" }
        drawer.body { |item| find_column_value(item, form, column).try(:link_url) }
      end
      drawer.column "#{form.id}/#{column.id}/link_label" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:link_label)}" }
        drawer.body { |item| find_column_value(item, form, column).try(:link_label) }
      end
    end

    def draw_column_youtube(drawer, form, column, value_type)
      drawer.column "#{form.id}/#{column.id}/url" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:url)}" }
        drawer.body { |item| find_column_value(item, form, column).try(:url) }
      end
      drawer.column "#{form.id}/#{column.id}/width" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:width)}" }
        drawer.body { |item| find_column_value(item, form, column).try(:width) }
      end
      drawer.column "#{form.id}/#{column.id}/height" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:height)}" }
        drawer.body { |item| find_column_value(item, form, column).try(:height) }
      end
      drawer.column "#{form.id}/#{column.id}/auto_width" do
        drawer.head { "#{form.name}/#{column.name}/#{value_type.t(:auto_width)}" }
        drawer.body do |item|
          find_column_value(item, form, column).try do |v|
            v.auto_width ? I18n.t("cms.column_youtube_auto_width.#{v.auto_width}") : nil
          end
        end
      end
    end

    def find_column_value(item, form, column)
      return if item.form_id != form.id
      item.column_values.where(column_id: column.id).first
    end
  end
end
