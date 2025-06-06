class Gws::Affair2::Aggregation::Downloader::Leave < Gws::Affair2::Aggregation::Downloader::Base
  def enum_csv(options)
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      drawer.column :user_id do
        drawer.head { t_agg(:user_id) }
        drawer.body { |item| item.user.name }
      end
      drawer.column :organization_uid do
        drawer.head { t_agg(:organization_uid) }
        drawer.body { |item| item.organization_uid }
      end
      drawer.column :date do
        drawer.head { t_agg(:date) }
        drawer.body { |item| item.date.strftime("%Y/%m") }
      end
      Gws::Affair2::Aggregation::Month.leave_type_options.each do |name, leave_type|
        drawer.column "leave_#{leave_type}_minutes" do
          drawer.head { t_agg("leave_#{leave_type}_minutes") }
          drawer.body { |item| item.send("leave_#{leave_type}_minutes") }
        end
      end
      drawer.column :leave_minutes do
        drawer.head { t_agg(:leave_minutes) }
        drawer.body { |item| item.leave_minutes }
      end
    end
    drawer.enum(items, options)
  end
end
