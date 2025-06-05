class Gws::Affair2::Aggregation::Downloader::Works < Gws::Affair2::Aggregation::Downloader::Base
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/BlockLength

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
      drawer.column :work_minutes2 do
        drawer.head { t_agg(:work_minutes2) }
        drawer.body { |item| item.work_minutes2 }
      end
      drawer.column :overtime_short_minutes1 do
        drawer.head { t_agg(:overtime_short_minutes1) }
        drawer.body { |item| item.overtime_short_minutes1 }
      end
      drawer.column :overtime_day_minutes1 do
        drawer.head { t_agg(:overtime_day_minutes1) }
        drawer.body { |item| item.overtime_day_minutes1 }
      end
      drawer.column :overtime_night_minutes1 do
        drawer.head { t_agg(:overtime_night_minutes1) }
        drawer.body { |item| item.overtime_night_minutes1 }
      end
      drawer.column :overtime_short_minutes2 do
        drawer.head { t_agg(:overtime_short_minutes2, threshold: monthly_threshold_hour) }
        drawer.body { |item| item.overtime_short_minutes2 }
      end
      drawer.column :overtime_day_minutes2 do
        drawer.head { t_agg(:overtime_day_minutes2, threshold: monthly_threshold_hour) }
        drawer.body { |item| item.overtime_day_minutes2 }
      end
      drawer.column :overtime_night_minutes2 do
        drawer.head { t_agg(:overtime_night_minutes2, threshold: monthly_threshold_hour) }
        drawer.body { |item| item.overtime_night_minutes2 }
      end
      drawer.column :compens_overtime_day_minutes1 do
        drawer.head { t_agg(:compens_overtime_day_minutes1) }
        drawer.body { |item| item.compens_overtime_day_minutes1 }
      end
      drawer.column :compens_overtime_night_minutes1 do
        drawer.head { t_agg(:compens_overtime_night_minutes1) }
        drawer.body { |item| item.compens_overtime_night_minutes1 }
      end
      drawer.column :settle_overtime_day_minutes1 do
        drawer.head { t_agg(:settle_overtime_day_minutes1) }
        drawer.body { |item| item.settle_overtime_day_minutes1 }
      end
      drawer.column :settle_overtime_night_minutes1 do
        drawer.head { t_agg(:settle_overtime_night_minutes1) }
        drawer.body { |item| item.settle_overtime_night_minutes1 }
      end
      drawer.column :compens_overtime_day_minutes2 do
        drawer.head { t_agg(:compens_overtime_day_minutes2, threshold: monthly_threshold_hour) }
        drawer.body { |item| item.compens_overtime_day_minutes2 }
      end
      drawer.column :compens_overtime_night_minutes2 do
        drawer.head { t_agg(:compens_overtime_night_minutes2, threshold: monthly_threshold_hour) }
        drawer.body { |item| item.compens_overtime_night_minutes2 }
      end
      drawer.column :settle_overtime_day_minutes2 do
        drawer.head { t_agg(:settle_overtime_day_minutes2, threshold: monthly_threshold_hour) }
        drawer.body { |item| item.settle_overtime_day_minutes2 }
      end
      drawer.column :settle_overtime_night_minutes2 do
        drawer.head { t_agg(:settle_overtime_night_minutes2, threshold: monthly_threshold_hour) }
        drawer.body { |item| item.settle_overtime_night_minutes2 }
      end
      drawer.column :overtime_minutes do
        drawer.head { t_agg(:overtime_minutes) }
        drawer.body { |item| item.overtime_minutes }
      end
    end
    drawer.enum(items, options)
  end

  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/BlockLength
end
