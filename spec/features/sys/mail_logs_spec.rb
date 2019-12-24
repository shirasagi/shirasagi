require 'spec_helper'

describe "sys_mail_logs", type: :feature, dbscope: :example, js: true do
  let(:index_path) { sys_mail_logs_path }
  let(:show_path) { sys_mail_log_path item }
  let(:decode_path) { decode_sys_mail_log_path item }
  let(:delete_path) { delete_sys_mail_log_path item }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(current_path).not_to eq sns_login_path
  end

  context "with auth" do
    before { login_sys_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    context "with utf-8 mail" do
      let(:item) { create :sys_mail_log_utf8 }

      it "#show" do
        visit show_path
        expect(current_path).not_to eq sns_login_path
        expect(first('#addon-basic textarea').value).to include("charset=utf-8")
      end

      it "#decode" do
        visit decode_path
        expect(current_path).not_to eq sns_login_path
        expect(first('#addon-basic textarea').value).to include("「市へのお問い合わせ」に入力がありました。")
      end

      it "#delete" do
        visit delete_path
        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      end
    end

    context "with iso mail" do
      let(:item) { create :sys_mail_log_iso }

      it "#show" do
        visit show_path
        expect(current_path).not_to eq sns_login_path
        expect(first('#addon-basic textarea').value).to include("charset=iso-2022-jp")
      end

      it "#decode" do
        visit decode_path
        expect(current_path).not_to eq sns_login_path
        expect(first('#addon-basic textarea').value).to include("「市へのお問い合わせ」に入力がありました。")
      end

      it "#delete" do
        visit delete_path
        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      end
    end
  end
end
