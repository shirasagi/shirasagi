require 'spec_helper'

describe "sys_test", type: :feature, dbscope: :example do
  subject(:index_path) { sys_diag_main_path }

  before do
    ActionMailer::Base.deliveries.clear
  end

  after do
    ActionMailer::Base.deliveries.clear
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_sys_user }

    it do
      visit index_path
      click_on I18n.t("ss.buttons.send")
      wait_for_notice "Sent Successfully"

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq sys_user.email
      expect(mail.to.first).to eq sys_user.email
      expect(mail.subject).to eq "TEST MAIL"
      expect(mail.decoded.to_s).to include("Message")
    end
  end
end
