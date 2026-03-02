require 'spec_helper'

describe "webmail_mails", type: :feature, dbscope: :example, imap: true, js: true do
  let(:user) { webmail_imap }
  let(:index_path) { webmail_mails_path(account: 0) }

  let!(:item_subject1) { unique_id }
  let!(:item_subject2) { unique_id }
  let!(:item_subject3) { unique_id }

  def get_last_logged_in
    expect(MongoidStore::Session.count).to eq 1
    data = MongoidStore::Session.first.data

    expect(data.dig("user", "user_id")).to eq user.id
    data.dig("user", "last_logged_in")
  end

  before do
    @save_webmail_auto_save = SS.config.webmail.auto_save
    # keep_interval を 0 にすると、定期送信を実行しない
    SS.config.replace_value_at(:webmail, :auto_save, { first_interval: 0, keep_interval: 0 })
  end

  after do
    SS.config.replace_value_at(:webmail, :auto_save, @save_webmail_auto_save)
  end

  context "auto save api は last_logged_in を更新しない" do
    before do
      login_user(user)
      ActionMailer::Base.deliveries.clear
    end

    after do
      ActionMailer::Base.deliveries.clear
    end

    it do
      visit index_path
      last_logged_in = get_last_logged_in

      # last_logged_in を更新する為、新規作成に行く前に少し待つ
      sleep(1)

      wait_for_js_ready
      new_window = window_opened_by { click_on I18n.t('ss.links.new') }
      within_window new_window do
        wait_for_document_loading
        wait_for_js_ready

        expect(get_last_logged_in).not_to eq last_logged_in
        last_logged_in = get_last_logged_in

        within "form#item-form" do
          fill_in "item[subject]", with: item_subject1
        end

        # 少し待った後 auto save api を実行するが last_logged_in は更新されない
        sleep(1)
        page.execute_script("window.WEBMAIL_AutoSave();")
        expect(page).to have_css(".webmail-auto-save-notice[data-count=\"0\"]")

        expect(Webmail::AutoSave.count).to eq 1
        auto_save = Webmail::AutoSave.first
        expect(auto_save.state).to eq "ready"
        expect(auto_save.subject).to eq item_subject1

        expect(get_last_logged_in).to eq last_logged_in

        within "form#item-form" do
          fill_in "item[subject]", with: item_subject2
        end

        # 少し待った後 auto save api を実行するが last_logged_in は更新されない
        sleep(1)
        page.execute_script("window.WEBMAIL_AutoSave();")
        expect(page).to have_css(".webmail-auto-save-notice[data-count=\"1\"]")

        expect(Webmail::AutoSave.count).to eq 1
        auto_save = Webmail::AutoSave.first
        expect(auto_save.state).to eq "ready"
        expect(auto_save.subject).to eq item_subject2

        within "form#item-form" do
          fill_in "item[subject]", with: item_subject3
        end

        # 少し待った後 auto save api を実行するが last_logged_in は更新されない
        sleep(1)
        page.execute_script("window.WEBMAIL_AutoSave();")
        expect(page).to have_css(".webmail-auto-save-notice[data-count=\"2\"]")

        expect(Webmail::AutoSave.count).to eq 1
        auto_save = Webmail::AutoSave.first
        expect(auto_save.state).to eq "ready"
        expect(auto_save.subject).to eq item_subject3
      end
    end
  end
end
