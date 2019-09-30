require 'spec_helper'

describe "gws_attendance_time_card", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:index_path) { gws_presence_users_path site }

  before { login_gws_user }

  context 'change presence' do
    before do
      @save_config = SS.config.gws.dig("presence")

      conf = @save_config.dup
      conf["sync_timecard"]["disable"] = false
      SS.config.replace_value_at(:gws, :presence, conf)
    end

    after do
      SS.config.replace_value_at(:env, :presence, @save_config)
    end

    context "user_presence already created" do
      let!(:user_presence) { create :gws_user_presence, user: user, site: site, state: "" }

      xit do
        visit gws_attendance_main_path(site)
        within '.today .action .enter' do
          page.accept_confirm do
            click_on I18n.t('gws/attendance.buttons.punch')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
        expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"

        visit gws_attendance_main_path(site)
        within '.today .action .leave' do
          page.accept_confirm do
            click_on I18n.t('gws/attendance.buttons.punch')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
        expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "leave"
      end
    end

    context "user_presence not exists" do
      xit do
        visit gws_attendance_main_path(site)
        within '.today .action .enter' do
          page.accept_confirm do
            click_on I18n.t('gws/attendance.buttons.punch')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
        expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "available"

        visit gws_attendance_main_path(site)
        within '.today .action .leave' do
          page.accept_confirm do
            click_on I18n.t('gws/attendance.buttons.punch')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('gws/attendance.notice.punched'))
        expect(Gws::User.find(gws_user.id).user_presence(site).state).to eq "leave"
      end
    end
  end
end
