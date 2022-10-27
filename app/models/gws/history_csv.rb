class Gws::HistoryCsv
  include ActiveModel::Model

  attr_accessor :site, :criteria

  def enum_csv(options = {})
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      drawer.column :id
      drawer.column :session_id
      drawer.column :request_id
      drawer.column :user_name do
        drawer.body do |item|
          Gws::HistoriesController.helpers.gws_public_user_long_name(item.user_long_name, cur_site: site)
        end
      end
      drawer.column :uid do
        drawer.head { Gws::User.t(:uid) }
        drawer.body { |item| item.user.try(:uid) }
      end
      drawer.column :severity do
        drawer.body { |item| I18n.t("gws.history.severity.#{item.severity}") }
      end
      drawer.column :mode
      drawer.column :model
      drawer.column :module do
        drawer.head { I18n.t("ss.module") }
        drawer.body { |item| I18n.t("modules.#{item.module_key}") }
      end
      drawer.column :controller
      drawer.column :job
      drawer.column :item_id
      drawer.column :path
      drawer.column :action
      drawer.column :updated_field_names
      drawer.column :message
      drawer.column :created
    end

    drawer.enum(criteria, options)
  end
end
