require 'spec_helper'

describe "sys_diag_mails", type: :feature, dbscope: :example, js: true do
  before do
    ActionMailer::Base.deliveries.clear
  end

  after do
    ActionMailer::Base.deliveries.clear
  end

  context "without sites" do
    let(:from) { unique_email }

    it do
      login_sys_user to: sys_diag_mails_path
      within "form#item-form" do
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
      expect(mail.message_id).to end_with("@#{SS.config.gws.canonical_domain}.mail")
    end
  end

  context "with manual from" do
    let!(:group) { create :sys_group }
    let!(:site) do
      create :cms_site_unique, sender_name: unique_id, sender_email: unique_email, group_ids: [ group.id ]
    end
    let(:from) { unique_email }

    before do
      sys_user.add_to_set(group_ids: group.id)
    end

    it do
      login_sys_user to: sys_diag_mails_path
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
      expect(mail.message_id).to end_with("@#{SS.config.gws.canonical_domain}.mail")
    end
  end

  context "with cms site as a from address" do
    let!(:group) { create :sys_group }
    let!(:site) do
      create :cms_site_unique, sender_name: unique_id, sender_email: unique_email, group_ids: [ group.id ]
    end

    before do
      sys_user.add_to_set(group_ids: group.id)
    end

    it do
      login_sys_user to: sys_diag_mails_path
      within "form#item-form" do
        select site.name, from: "item[from_site]"
        click_on I18n.t("ss.buttons.send")
      end
      wait_for_notice "Sent Successfully"

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq site.sender_email
      expect(mail.to.first).to eq sys_user.email
      expect(mail_subject(mail)).to eq "TEST MAIL"
      expect(mail_body(mail)).to include("Message")
      expect(mail.message_id).to end_with("@#{SS.config.gws.canonical_domain}.mail")
    end
  end

  context "with gws site as a from address" do
    let!(:group) { create :gws_group, sender_name: unique_id, sender_email: unique_email }

    before do
      sys_user.add_to_set(group_ids: group.id)
    end

    it do
      login_sys_user to: sys_diag_mails_path
      within "form#item-form" do
        select group.name, from: "item[from_site]"
        click_on I18n.t("ss.buttons.send")
      end
      wait_for_notice "Sent Successfully"

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq group.sender_email
      expect(mail.to.first).to eq sys_user.email
      expect(mail_subject(mail)).to eq "TEST MAIL"
      expect(mail_body(mail)).to include("Message")
      expect(mail.message_id).to end_with("@#{SS.config.gws.canonical_domain}.mail")
    end
  end
end
