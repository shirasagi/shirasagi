require 'spec_helper'

describe "webmail_users", type: :feature, dbscope: :example do
  before { login_webmail_admin }

  context "user extension" do
    let(:setting) { Webmail::ImapSetting.default }
    let(:imap) { Webmail::Imap::Base.new_by_user(webmail_admin, setting) }
    let(:quota_limit) { 10 }
    let(:quota_usage) { rand(1..quota_limit) }

    context "with quota" do
      let(:quota) { Webmail::Quota.where(imap.quota.quota_root_scope).first_or_create }
      let(:quota_label) { "#{(quota.usage * 1_024).to_fs(:human_size)}/#{(quota.quota * 1_024).to_fs(:human_size)}" }

      before do
        quota.usage = quota_usage
        quota.quota = quota_limit
        quota.reloaded = Time.zone.now
        quota.save!
      end

      it do
        visit webmail_users_path
        click_on webmail_admin.name

        within "#addon-webmail-agents-addons-user_extension" do
          within first("table.index tr") do
            expect(page).to have_css("div.label", text: quota_label)
          end
        end
      end
    end

    context "without quota" do
      let(:quota_label) { "--/--" }

      it do
        visit webmail_users_path
        click_on webmail_admin.name

        within "#addon-webmail-agents-addons-user_extension" do
          within first("table.index tr") do
            expect(page).to have_css("div.label", text: quota_label)
          end
        end
      end
    end
  end
end
