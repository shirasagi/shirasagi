namespace :gws do
  namespace :affair do
    namespace :overtime_file do
      task save_day_results: :environment do
        Gws::Affair::OvertimeFile.each do |item|
          next if item.result.blank?
          puts "#{item.id} #{item.name}"
          def item.result_closed?; false end
          item.save_day_results
        end
      end

      task update_affair_v4: :environment do
        puts "# leave_settings"
        Gws::Affair::LeaveSetting.each do |item|
          next if item.year

          site = item.site
          user = item.user
          start_at = item[:start_at]
          end_at = item[:end_at]

          years = Gws::Affair::CapitalYear.site(site).or([
            { :start_date.lte => start_at, :close_date.gte => start_at },
            { :start_date.lte => end_at, :close_date.gte => end_at },
          ]).to_a

          years.each do |year|
            new_item = item.class.new
            new_item.cur_site = site
            new_item.cur_user = user
            new_item.year = year
            new_item.target_user = user
            new_item.user_ids = item.user_ids
            new_item.count = item.count
            if new_item.save
              puts "save leave_setting #{user.try(:name)} #{year.name}"
            else
              puts "save faild leave_setting #{user.try(:name)} #{year.name} #{item.errors.full_messages.join(", ")}"
            end
          end

          puts "remove old leave_setting #{user.try(:name)}（#{item.id}）"
          item.destroy
        end

        puts "# leave_files"
        Gws::Affair::LeaveFile.each do |item|
          leave_dates = item[:leave_dates].to_a
          next if leave_dates.blank?
          next if leave_dates.map(&:class).uniq == [BSON::Document]

          item.unset(:leave_dates)

          def item.validate_date
            duty_calendar = user.effective_duty_calendar(site)
            changed_at = duty_calendar.affair_next_changed(start_at)
            self.date = changed_at.advance(days: -1).change(hour: 0, min: 0, sec: 0)

            # 実際に休日となった日時を保存
            start_date = date
            end_date = end_at.change(hour: 0, min: 0, sec: 0)

            self.in_leave_dates = []
            (start_date..end_date).each do |date|
              next if duty_calendar.leave_day?(date)

              affair_start_at = duty_calendar.affair_start(date)
              affair_end_at = duty_calendar.affair_end(date)

              if start_date == date
                affair_start_at = start_at
              end
              if end_date == date
                affair_end_at = end_at
              end

              working_minute, _ = duty_calendar.working_minute(date, affair_start_at, affair_end_at)
              next if working_minute == 0
              minute = Gws::Affair::Utils.format_leave_minutes(working_minute)

              self.in_leave_dates << OpenStruct.new(
                date: date,
                start_at: affair_start_at,
                end_at: affair_end_at,
                working_minute: working_minute,
                minute: minute
              )
            end
          end
          def item.set_updated; end

          if item.save
            puts "save leave file #{item.name}"
          else
            puts "save faild leave file #{item.name}"
          end
        end

        puts "# gws_roles"
        Gws::Role.each do |item|
          roles = []
          permissions = item.permissions.to_a

          if permissions.include?("read_private_gws_affair_shift_calendars")
            roles << "use_gws_affair_shift_calendars"
          end
          if permissions.include?("read_other_gws_affair_shift_calendars")
            roles << "manage_private_gws_affair_shift_calendars"
          end
          if permissions.include?("read_other_gws_affair_shift_calendars") && permissions.include?("all_gws_affair_overtime_aggregate")
            roles << "manage_all_gws_affair_shift_calendars"
          end

          roles = roles - permissions
          next if roles.blank?

          item.permissions = roles + permissions
          if item.save
            puts "save role #{item.id}"
          else
            puts "save faild role #{item.id}"
          end
        end
      end
    end
  end
end
