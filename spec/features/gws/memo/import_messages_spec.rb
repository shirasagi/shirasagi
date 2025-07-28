require 'spec_helper'

describe 'gws_memo_import_messages', type: :feature, dbscope: :example do
  let!(:site) { gws_site }

  before { login_gws_user }

  it do
    visit gws_memo_import_messages_path(site: site)

    within "form#item-form" do
      attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/memo/messages.zip"
      click_on I18n.t("ss.import")
    end

    wait_for_notice I18n.t("gws/memo/message.notice.start_import")

    expect(Gws::Memo::Message.all.count).to eq 8
    Gws::Memo::Message.all.find_by(subject: "宛先　→ 共有アドレスメッセージ").tap do |message|
      expect(message.site_id).to eq site.id
      expect(message.text).to include("宛先　→ 共有アドレスメッセージ")
      expect(message.html).to be_blank
      expect(message.format).to eq "text"
      expect(message.filtered).to include(gws_user.id.to_s)
      expect(message.state).to eq "public"
    end
  end
end
