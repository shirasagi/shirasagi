require 'spec_helper'

describe 'gws_memo_import_messages', type: :feature, dbscope: :example do
  let!(:site) { gws_site }
  let!(:shared_address_group1) { create :gws_shared_address_group, name: "企画政策部 政策課" }
  let!(:shared_address_group2) { create :gws_shared_address_group, name: "企画政策部 広報課" }
  let!(:shared_address_group3) { create :gws_shared_address_group, name: "危機管理部 管理課" }
  let!(:shared_address_group4) { create :gws_shared_address_group, name: "危機管理部 防災課" }

  let!(:webmail_address_group1) { create :webmail_address_group, cur_user: gws_user, name: "企画政策部 広報課" }
  let!(:webmail_address_group2) { create :webmail_address_group, cur_user: gws_user, name: "企画政策部 政策課" }
  let!(:webmail_address_group3) { create :webmail_address_group, cur_user: gws_user, name: "危機管理部 広報課" }
  let!(:webmail_address_group4) { create :webmail_address_group, cur_user: gws_user, name: "危機管理部 政策課" }

  before { login_gws_user }

  it do
    visit gws_memo_import_messages_path(site: site)

    within "form#item-form" do
      attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/memo/messages.zip"
      click_on I18n.t("ss.import")
    end

    expect(page).to have_css('#notice', text: I18n.t("gws/memo/message.notice.start_import"))

    expect(Gws::Memo::Message.all.count).to eq 1
    Gws::Memo::Message.all.first.tap do |message|
      expect(message.site_id).to eq site.id
      expect(message.subject).to eq "サイト改善プロジェクト"
      expect(message.text).to include "シラサギ市ホームページの改善プロジェクト"
      expect(message.html).to be_blank
      expect(message.format).to eq "text"
      expect(message.filtered).to include(gws_user.id.to_s)
      expect(message.state).to eq "public"
    end
  end

  it "import to_shared_address_group" do
    visit gws_memo_import_messages_path(site: site)

    within "form#item-form" do
      attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/memo/shared_group_messages.zip"
      click_on I18n.t("ss.import")
    end

    expect(page).to have_css('#notice', text: I18n.t("gws/memo/message.notice.start_import"))

    expect(Gws::Memo::Message.all.count).to eq 1
    Gws::Memo::Message.all.first.tap do |message|
      expect(message.site_id).to eq site.id
      expect(message.subject).to eq "庁舎一斉停電のお知らせ"
      expect(message.to_shared_address_group_ids).to include shared_address_group1.id
      expect(message.to_shared_address_group_ids).to include shared_address_group2.id
      expect(message.to_shared_address_group_ids).to include shared_address_group3.id
      expect(message.to_shared_address_group_ids).to include shared_address_group4.id
    end
  end

  it "import to_webmail_address_group" do
    visit gws_memo_import_messages_path(site: site)

    within "form#item-form" do
      attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/memo/webmail_group.zip"
      click_on I18n.t("ss.import")
    end

    expect(page).to have_css('#notice', text: I18n.t("gws/memo/message.notice.start_import"))

    expect(Gws::Memo::Message.all.count).to eq 1
    Gws::Memo::Message.all.first.tap do |message|
      expect(message.site_id).to eq site.id
      expect(message.subject).to eq "test"
      expect(message.to_webmail_address_group_ids).to include webmail_address_group1.id
      expect(message.to_webmail_address_group_ids).to include webmail_address_group2.id
      expect(message.to_webmail_address_group_ids).to include webmail_address_group3.id
      expect(message.to_webmail_address_group_ids).to include webmail_address_group4.id
    end
  end

  it "import multipart mail" do
    visit gws_memo_import_messages_path(site: site)

    within "form#item-form" do
      attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/memo/multipart.zip"
      click_on I18n.t("ss.import")
    end

    expect(page).to have_css('#notice', text: I18n.t("gws/memo/message.notice.start_import"))

    expect(Gws::Memo::Message.all.count).to eq 1
    Gws::Memo::Message.all.first.tap do |message|
      expect(message.site_id).to eq site.id
      expect(message.subject).to eq "シラサギ市 マルチパートメッセージ"
      expect(message.html).to include "<p>マルチパートプロジェクトです</p>"
      expect(message.format).to eq "html"
      expect(message.file_ids.length).to eq 1
      expect(message.filtered).to include(gws_user.id.to_s)
      expect(message.state).to eq "public"
    end
  end
end
