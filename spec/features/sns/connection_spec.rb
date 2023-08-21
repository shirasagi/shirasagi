require 'spec_helper'

describe "sns_connection", type: :feature, dbscope: :example do
  let(:index_path) { sns_connection_path }

  context "with auth" do
    before { login_sys_user }

    it "#index" do
      visit index_path
      click_on I18n.t('sns.connection')
      expect(current_path).to eq index_path
      expect(page).to have_css('dt', text: I18n.t("sys.remote_addr"))
      expect(page).to have_css('dt', text: I18n.t("sys.user_agent"))
    end
  end
end
