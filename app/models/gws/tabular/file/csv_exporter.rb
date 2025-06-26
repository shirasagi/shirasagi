class Gws::Tabular::File::CsvExporter
  include ActiveModel::Model

  attr_accessor :site, :user, :space, :form, :release, :criteria

  def enum_csv(**options)
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      draw_exporters(drawer)
    end

    drawer.enum(criteria, options)
  end

  private

  def draw_exporters(drawer)
    form = Gws::Tabular.released_form(release, site: site)
    form ||= release.form
    columns = Gws::Tabular.released_columns(release, site: site)
    columns ||= form.columns.reorder(order: 1, id: 1).to_a

    draw_basic(drawer)
    draw_columns(drawer, columns)
    if form.workflow_enabled?
      draw_workflow(drawer)
    end
    draw_tail(drawer)
  end

  def draw_basic(drawer)
    drawer.column :id
  end

  def draw_columns(drawer, columns)
    columns.each do |column|
      if Gws::Tabular.i18n_column?(column)
        SS.each_locale_in_order do |lang|
          drawer.column "col_#{column.id}_#{lang}" do
            drawer.head { SS::Csv.escape_column_name_for_csv("#{column.name} (#{I18n.t("ss.options.lang.#{lang}")})") }
            drawer.body do |item|
              item.read_csv_value(column, locale: lang)
            end
          end
        end
      else
        drawer.column "col_#{column.id}" do
          drawer.head { SS::Csv.escape_column_name_for_csv(column.name) }
          drawer.body do |item|
            item.read_csv_value(column, locale: I18n.default_locale)
          end
        end
      end
    end
  end

  def draw_workflow(drawer)
    drawer.column :workflow_requested do
      drawer.head { I18n.t("gws/workflow.table.gws/workflow/file.requested") }
      drawer.body do |item|
        item.try(:requested) ? I18n.l(item.requested, format: :csv) : nil
      end
    end
    drawer.column :workflow_comment do
      drawer.head { Gws::Workflow2::File.t(:workflow_comment) }
      drawer.body do |item|
        item.try(:workflow_comment)
      end
    end
    drawer.column :workflow_state do
      drawer.head { Gws::Workflow2::File.t(:workflow_state) }
      drawer.body do |item|
        item.try(:workflow_state).present? ? I18n.t("workflow.state.#{item.workflow_state}") : nil
      end
    end
    drawer.column :workflow_approved do
      drawer.head { I18n.t("mongoid.attributes.workflow/approver.approved") }
      drawer.body do |item|
        item.try(:approved) ? I18n.l(item.approved, format: :csv) : nil
      end
    end
    if form.workflow_enabled?
      drawer.column :workflow_destination_treat_state do
        drawer.head { I18n.t("mongoid.attributes.gws/workflow2/destination_state.destination_treat_state") }
        drawer.body do |item|
          item.label(:destination_treat_state)
        end
      end
    end

    # 1.upto(Gws::Workflow2::Route::MAX_APPROVERS) do |level|
    #   drawer.column :workflow_approvers_or_circulations do
    #     drawer.head { I18n.t("workflow.csv.approvers_or_circulations") }
    #     drawer.body do |item|
    #       if type == :approver
    #         I18n.t('mongoid.attributes.workflow/model/route.level', level: level)
    #       else
    #         "#{I18n.t("workflow.circulation_step")} #{I18n.t('mongoid.attributes.workflow/model/route.level', level: level)}"
    #       end
    #     end
    #   end
    # end
  end

  def draw_tail(drawer)
    drawer.column :migration_errors do
      drawer.head { I18n.t("gws/tabular.csv_prefix") + I18n.t("mongoid.attributes.gws/tabular/file.migration_errors") }
      drawer.body do |item|
        if item.migration_errors.present?
          item.migration_errors.join("\n")
        end
      end
    end
    drawer.column :updated do
      drawer.head { I18n.t("gws/tabular.csv_prefix") + I18n.t("mongoid.attributes.ss/document.updated") }
    end
    drawer.column :created do
      drawer.head { I18n.t("gws/tabular.csv_prefix") + I18n.t("mongoid.attributes.ss/document.created") }
    end
  end

  def find_workflow_user_custom_data_value(item, name)
    return if item.workflow_user_custom_data.blank?

    custom_data = item.workflow_user_custom_data.find { |data| data["name"] == name }
    return unless custom_data

    custom_data["value"]
  end
end
