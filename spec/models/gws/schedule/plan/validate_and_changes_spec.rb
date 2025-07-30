require 'spec_helper'

RSpec.describe Gws::Schedule::Plan, type: :model, dbscope: :example do
  describe "validate and changes" do
    let!(:site) { gws_site }

    let(:text_type) { %w(plain cke markdown).sample }
    let(:text) do
      case text_type
      when 'cke'
        Array.new(2) { "<p>text-#{unique_id}</p>" }.join("\n")
      else
        Array.new(2) { "text-#{unique_id}" }.join("\n")
      end
    end
    let!(:member_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:member) { create :gws_user, group_ids: [ member_group.id ] }
    let!(:member_custom_group) { create :gws_custom_group, cur_site: site, member_ids: [ member.id ] }

    let!(:attendance_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:attendance_user) { create :gws_user, group_ids: [ attendance_group.id ] }

    let!(:approval_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:approval_user) { create :gws_user, group_ids: [ approval_group.id ] }

    let!(:readable_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:readable_user) { create :gws_user, group_ids: [ readable_group.id ] }
    let!(:readable_custom_group) { create :gws_custom_group, cur_site: site, member_ids: [ readable_user.id ] }

    let!(:admin_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:admin_user) { create :gws_user, group_ids: [ admin_group.id ] }
    let!(:admin_custom_group) { create :gws_custom_group, cur_site: site, member_ids: [ admin_user.id ] }

    let!(:facility) { create :gws_facility_item, cur_site: site }

    let(:file) { tmp_ss_file(contents: '0123456789', site: site, user: admin_user) }

    context "with a plan" do
      let(:start_at) { Time.zone.now.since(1.week).change(hour: 13) }
      let(:end_at) { start_at + 1.hour }

      subject do
        Gws::Schedule::Plan.create!(
          # Gws::Reference::User
          cur_user: admin_user,
          # Gws::Reference::Site
          cur_site: site,
          # Gws::Schedule::Priority
          priority: [1, 2, 3, 4, 5].sample,
          # Gws::Schedule::Planable
          state: %w(public closed).sample,
          name: "name-#{unique_id}",
          start_at: start_at,
          end_at: end_at,
          # Gws::Addon::Memo::NotifySetting (Gws::NotifySetting)
          notify_state: %w(enabled disabled).sample,
          # SS::Addon::Markdown
          text_type: text_type,
          text: text,
          # Gws::Addon::File
          file_ids: [ file.id ],
          # Gws::Addon::Member
          member_ids: [ member.id ],
          member_group_ids: [ member_group.id ],
          member_custom_group_ids: [ member_custom_group.id ],
          # Gws::Addon::Schedule::Attendance
          attendance_check_state: %w(disabled enabled).sample,
          attendances: [
            Gws::Schedule::Attendance.new(cur_user: attendance_user, attendance_state: %w(unknown attendance absence).sample)
          ],
          # Gws::Addon::Schedule::Facility
          facility_ids: [ facility.id ],
          # Gws::Addon::Schedule::FacilityColumnValues
          main_facility: facility,
          # facility_column_values: [xxx],
          # Gws::Addon::Schedule::Approval
          approval_state: %w(request approve deny).sample,
          approval_member_ids: [ approval_user.id ],
          # Gws::Addon::ReadableSetting
          readable_setting_range: 'select',
          readable_member_ids: [ readable_user.id ],
          readable_group_ids: [ readable_group.id ],
          readable_custom_group_ids: [ readable_custom_group.id ],
          # Gws::Addon::GroupPermission
          user_ids: [ admin_user.id ],
          group_ids: [ admin_group.id ],
          custom_group_ids: [ admin_custom_group.id ]
        )
      end

      it do
        Gws::Schedule::Plan.find(subject.id).tap do |item|
          expect(item.valid?).to be_truthy
          # 検証しただけでは、差分は発生しないはず。
          expect(item.changes).to be_blank
        end
      end
    end

    context "with allday plan" do
      let(:start_on) { Time.zone.now.since(1.week).to_date }
      let(:end_on) { start_on }

      subject do
        Gws::Schedule::Plan.create!(
          # Gws::Reference::User
          cur_user: admin_user,
          # Gws::Reference::Site
          cur_site: site,
          # Gws::Schedule::Priority
          priority: [1, 2, 3, 4, 5].sample,
          # Gws::Schedule::Planable
          state: %w(public closed).sample,
          name: "name-#{unique_id}",
          allday: 'allday',
          start_on: start_on,
          end_on: end_on,
          # Gws::Addon::Memo::NotifySetting (Gws::NotifySetting)
          notify_state: %w(enabled disabled).sample,
          # SS::Addon::Markdown
          text_type: text_type,
          text: text,
          # Gws::Addon::File
          file_ids: [ file.id ],
          # Gws::Addon::Member
          member_ids: [ member.id ],
          member_group_ids: [ member_group.id ],
          member_custom_group_ids: [ member_custom_group.id ],
          # Gws::Addon::Schedule::Attendance
          attendance_check_state: %w(disabled enabled).sample,
          attendances: [
            Gws::Schedule::Attendance.new(cur_user: attendance_user, attendance_state: %w(unknown attendance absence).sample)
          ],
          # Gws::Addon::Schedule::Facility
          facility_ids: [ facility.id ],
          # Gws::Addon::Schedule::FacilityColumnValues
          main_facility: facility,
          # facility_column_values: [xxx],
          # Gws::Addon::Schedule::Approval
          approval_state: %w(request approve deny).sample,
          approval_member_ids: [ approval_user.id ],
          # Gws::Addon::ReadableSetting
          readable_setting_range: 'select',
          readable_member_ids: [ readable_user.id ],
          readable_group_ids: [ readable_group.id ],
          readable_custom_group_ids: [ readable_custom_group.id ],
          # Gws::Addon::GroupPermission
          user_ids: [ admin_user.id ],
          group_ids: [ admin_group.id ],
          custom_group_ids: [ admin_custom_group.id ]
        )
      end

      it do
        Gws::Schedule::Plan.find(subject.id).tap do |item|
          expect(item.valid?).to be_truthy
          # 検証しただけでは、差分は発生しないはず。
          expect(item.changes).to be_blank
        end
      end
    end
  end
end
