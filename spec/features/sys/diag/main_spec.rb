require 'spec_helper'

describe "sys_test", type: :feature, dbscope: :example, js: true do
  subject(:index_path) { sys_diag_main_path }

  before do
    ActionMailer::Base.deliveries.clear
  end

  after do
    ActionMailer::Base.deliveries.clear
  end

  it "without auth" do
    login_ss_user to: index_path
    expect(page).to have_title(/403 Forbidden/)
  end

  context "with auth" do
    let(:from) { unique_email }
    it do
      login_sys_user to: index_path
      within "form#item-form" do
        choose "手動で入力"
        fill_in "item[from_manual]", with: from
        click_on I18n.t("ss.buttons.send")
      end
      wait_for_notice "Sent Successfully"

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq from
      expect(mail.to.first).to eq sys_user.email
      expect(mail_subject(mail)).to eq "TEST MAIL"
      expect(mail_body(mail)).to include("Message")
    end
  end
end
