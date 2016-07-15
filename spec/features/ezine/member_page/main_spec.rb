require 'spec_helper'

describe "ezine_member_page_main", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create(:ezine_node_member_page, cur_site: site) }
  let(:index_path) { ezine_member_pages_path(site: site, cid: node) }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).to eq index_path
    end

    describe "node conf" do
      let!(:member) { cms_member }

      it do
        member.reload
        expect(member.subscription_ids).to eq []

        visit index_path
        click_on "フォルダー設定"
        click_on "編集する"

        fill_in "item[signature_html]", with: "<hr><p>#{unique_id}<p>"
        fill_in "item[signature_text]", with: "----\n#{unique_id}"
        fill_in "item[sender_name]", with: unique_id
        fill_in "item[sender_email]", with: "#{unique_id}@example.jp"
        select "必須", from: "item[subscription_constraint]"
        click_on "保存"

        expect(page).to have_css("#notice", text: "保存しました。")

        # after setting subscription_constraint to required, existing member's subscription_ids is chagned.
        member.reload
        expect(member.subscription_ids).to eq [ node.id ]

        member1 = create :cms_member, cur_site: site
        expect(member1.subscription_ids).to eq [ node.id ]
      end
    end

    describe "create item" do
      let(:new_path) { new_ezine_member_page_path site, node }
      let(:name) { "test #{unique_id}" }
      let(:html) { "<p>test #{unique_id}</p>" }
      let(:text) { "test #{unique_id}" }
      let(:show_path) { ezine_member_page_path site, node, Ezine::Page.last }

      it do
        visit index_path

        click_link "新規作成"

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[html]", with: html
          fill_in "item[text]", with: text
          click_button "保存"
        end

        expect(status_code).to eq 200
        expect(current_path).to eq show_path
        expect(page).to have_css("div#addon-basic .addon-body dl.see dd", text: name)
        # expect(page).to have_css("div#addon-ezine-agents-addons-body .addon-body dl.see dd", text: name)

        click_link "一覧へ戻る"
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page).to have_css(".list-items .list-item .info .up", count: 1)
        expect(page).to have_css(".list-items .list-item .info .title", count: 1)
      end
    end

    describe "edit item" do
      let(:html) { "<p>test #{unique_id}</p>" }
      let(:text) { "test #{unique_id}" }
      let!(:item) { create(:ezine_page, cur_site: site, cur_node: node, cur_user: cms_user) }

      it do
        visit index_path

        click_link item.name
        click_link "編集する"

        within "form#item-form" do
          fill_in "item[html]", with: html
          fill_in "item[text]", with: text
          click_button "保存"
        end

        expect(page).to have_css("div#addon-basic .addon-body dl.see dd", text: item.name)
        # expect(page).to have_css("div#addon-ezine-agents-addons-body .addon-body dl.see dd", text: name)

        click_link "一覧へ戻る"

        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page).to have_css(".list-items .list-item .info .up", count: 1)
        expect(page).to have_css(".list-items .list-item .info .title", count: 1)
      end
    end

    describe "delete item" do
      let(:html) { "<p>test #{unique_id}</p>" }
      let(:text) { "test #{unique_id}" }
      let!(:item) { create(:ezine_page, cur_site: site, cur_node: node, cur_user: cms_user) }

      it do
        visit index_path

        click_link item.name
        click_link "削除する"

        within "form" do
          expect(page).to have_css("div#addon-basic .addon-body dl.see dd", text: item.name)
          click_button "削除"
        end

        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page).to have_css(".list-items .list-item .info .up", count: 1)
        expect(page).not_to have_css(".list-items .list-item .info .title")
      end
    end

    describe "test deliver" do
      let(:html) { "<p>test #{unique_id}</p>" }
      let(:text) { "test #{unique_id}" }
      let!(:item) { create(:ezine_page, cur_site: site, cur_node: node, cur_user: cms_user, html: html, text: text) }
      let(:email) { "#{unique_id}@example.jp" }

      it "search test member" do
        visit index_path

        click_link "フォルダー設定"
        click_link "テスト読者"
        click_link "新規作成"

        within "form" do
          fill_in "item[email]", with: email
          select I18n.t("ezine.options.email_type.text"), from: "item[email_type]"
          click_button "保存"
        end

        click_link "フォルダー設定"
        click_link "テスト読者"
        expect(page).to have_css(".list-item .title", text: email)

        fill_in "s[keyword]", with: email
        click_on "検索"
        expect(page).to have_css(".list-item .title", text: email)

        fill_in "s[keyword]", with: unique_id
        click_on "検索"
        expect(page).not_to have_css(".list-item .title", text: email)
      end

      it "sends text mail" do
        visit index_path

        click_link "フォルダー設定"
        click_link "テスト読者"
        click_link "新規作成"

        within "form" do
          fill_in "item[email]", with: email
          select I18n.t("ezine.options.email_type.text"), from: "item[email_type]"
          click_button "保存"
        end

        expect(status_code).to eq 200
        expect(page).to have_css(".see dd", text: email)
        expect(page).to have_css(".see dd", text: I18n.t("ezine.options.email_type.text"))

        click_link "会員向けメール配信"
        click_link item.name
        click_link "テスト読者"

        expect(status_code).to eq 200
        expect(page).to have_css(".list-items .list-item .info .title", text: email)
        expect(page).to have_css(".list-items .list-item .info .meta .email-type", text: I18n.t("ezine.options.email_type.text"))

        click_link "会員向けメール配信"
        click_link item.name
        click_link "テスト配信"

        within "form" do
          expect(page).to have_css(".ezine-form dd", text: item.name)
          expect(page).to have_css(".ezine-form dd textarea", text: email)
          click_button "テスト配信"
        end

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail).not_to be_nil
        # expect(mail.from.first).to eq "test@example.jp"
        expect(mail.to.first).to eq email
        expect(mail.subject).to eq item.name
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include(item.text)

        expect(Ezine::SentLog.count).to eq 0
      end

      it "sends html mail" do
        visit index_path

        click_link "フォルダー設定"
        click_link "テスト読者"
        click_link "新規作成"

        within "form" do
          fill_in "item[email]", with: email
          select I18n.t("ezine.options.email_type.html"), from: "item[email_type]"
          click_button "保存"
        end

        expect(status_code).to eq 200
        expect(page).to have_css(".see dd", text: email)
        expect(page).to have_css(".see dd", text: I18n.t("ezine.options.email_type.html"))

        click_link "会員向けメール配信"
        click_link item.name
        click_link "テスト読者"

        expect(status_code).to eq 200
        expect(page).to have_css(".list-items .list-item .info .title", text: email)
        expect(page).to have_css(".list-items .list-item .info .meta .email-type", text: I18n.t("ezine.options.email_type.html"))

        click_link "会員向けメール配信"
        click_link item.name
        click_link "テスト配信"

        within "form" do
          expect(page).to have_css(".ezine-form dd", text: item.name)
          expect(page).to have_css(".ezine-form dd textarea", text: email)
          click_button "テスト配信"
        end

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail).not_to be_nil
        # expect(mail.from.first).to eq "test@example.jp"
        expect(mail.to.first).to eq email
        expect(mail.subject).to eq item.name
        expect(mail.body.multipart?).to be_truthy
        expect(mail.body.parts.count).to eq 2
        expect(mail.body.parts[0].body).to include(item.text)
        expect(mail.body.parts[1].body).to include(item.html)

        expect(Ezine::SentLog.count).to eq 0
      end
    end

    describe "deliver" do
      let(:html) { "<p>test #{unique_id}</p>" }
      let(:text) { "test #{unique_id}" }
      let!(:item) { create(:ezine_page, cur_site: site, cur_node: node, cur_user: cms_user, html: html, text: text) }
      let(:email) { "#{unique_id}@example.jp" }

      before do
        allow(SS::RakeRunner).to receive(:run_async).and_wrap_original do |_, *args|
          ::Ezine::Task.deliver args[1].sub("page_id=", "")
        end
      end

      describe "sends text mail" do
        before do
          create(:cms_member, email: email, email_type: 'text', subscription_ids: [ node.id ])
        end

        it do
          visit index_path

          click_link "会員向けメール配信"
          click_link item.name
          click_link "購読会員"

          expect(status_code).to eq 200
          expect(page).to have_css(".list-items .list-item .info .meta .email", text: email)

          click_link "会員向けメール配信"
          click_link item.name
          click_link "本配信"

          within "form" do
            expect(page).to have_css(".ezine-form dd", text: item.name)
            expect(page).to have_css(".ezine-form dd textarea", text: email)
            click_button "本配信"
          end

          expect(ActionMailer::Base.deliveries.length).to eq 1
          mail = ActionMailer::Base.deliveries.first
          expect(mail).not_to be_nil
          # expect(mail.from.first).to eq "test@example.jp"
          expect(mail.to.first).to eq email
          expect(mail.subject).to eq item.name
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item.text)

          expect(Ezine::SentLog.count).to eq 1
          Ezine::SentLog.first.tap do |log|
            expect(log.node_id).to eq node.id
            expect(log.page_id).to eq item.id
            expect(log.email).to eq email
          end
        end
      end

      describe "sends html mail" do
        before do
          create(:cms_member, email: email, email_type: 'html', subscription_ids: [ node.id ])
        end

        it do
          visit index_path

          click_link "会員向けメール配信"
          click_link item.name
          click_link "購読会員"

          expect(status_code).to eq 200
          expect(page).to have_css(".list-items .list-item .info .meta .email", text: email)

          click_link "会員向けメール配信"
          click_link item.name
          click_link "本配信"

          within "form" do
            expect(page).to have_css(".ezine-form dd", text: item.name)
            expect(page).to have_css(".ezine-form dd textarea", text: email)
            click_button "本配信"
          end

          expect(ActionMailer::Base.deliveries.length).to eq 1
          mail = ActionMailer::Base.deliveries.first
          expect(mail).not_to be_nil
          # expect(mail.from.first).to eq "test@example.jp"
          expect(mail.to.first).to eq email
          expect(mail.subject).to eq item.name
          expect(mail.body.multipart?).to be_truthy
          expect(mail.body.parts.count).to eq 2
          expect(mail.body.parts[0].body).to include(item.text)
          expect(mail.body.parts[1].body).to include(item.html)

          expect(Ezine::SentLog.count).to eq 1
          Ezine::SentLog.first.tap do |log|
            expect(log.node_id).to eq node.id
            expect(log.page_id).to eq item.id
            expect(log.email).to eq email
          end
        end
      end

      context "there is 3 nodes, 6 members" do
        let(:node0) { node }
        let(:node1) { create(:ezine_node_member_page, cur_site: site) }
        let(:node2) { create(:ezine_node_member_page, cur_site: site) }
        let(:email0) { email }
        let(:email1) { "#{unique_id}@example.jp" }
        let(:email2) { "#{unique_id}@example.jp" }
        let(:email3) { "#{unique_id}@example.jp" }
        let(:email4) { "#{unique_id}@example.jp" }
        let(:email5) { "#{unique_id}@example.jp" }
        let(:html) { "<p>test #{unique_id}</p>" }
        let(:text) { "test #{unique_id}" }
        let!(:item0) { create(:ezine_page, cur_site: site, cur_node: node0, cur_user: cms_user, html: html, text: text) }
        let!(:item1) { create(:ezine_page, cur_site: site, cur_node: node1, cur_user: cms_user, html: html, text: text) }
        let!(:item2) { create(:ezine_page, cur_site: site, cur_node: node2, cur_user: cms_user, html: html, text: text) }

        before do
          create(:cms_member, email: email0, email_type: 'text', subscription_ids: [ node0.id ])
          create(:cms_member, email: email1, email_type: 'text', subscription_ids: [ node1.id ])
          create(:cms_member, email: email2, email_type: 'text', subscription_ids: [ node2.id ])
          create(:cms_member, email: email3, email_type: 'html', subscription_ids: [ node0.id ])
          create(:cms_member, email: email4, email_type: 'html', subscription_ids: [ node1.id ])
          create(:cms_member, email: email5, email_type: 'html', subscription_ids: [ node2.id ])
        end

        it "sends item0" do
          visit ezine_member_pages_path(site: site, cid: node0)

          click_link item0.name
          click_link "本配信"
          within "form" do
            click_button "本配信"
          end

          expect(ActionMailer::Base.deliveries.length).to eq 2
          first_mail = ActionMailer::Base.deliveries.first
          expect(first_mail).not_to be_nil
          # expect(mail.from.first).to eq "test@example.jp"
          expect(first_mail.to.first).to eq email0
          expect(first_mail.subject).to eq item0.name
          expect(first_mail.body.multipart?).to be_falsey
          expect(first_mail.body.raw_source).to include(item0.text)

          last_mail = ActionMailer::Base.deliveries.last
          expect(last_mail).not_to be_nil
          expect(last_mail.to.first).to eq email3
          expect(last_mail.subject).to eq item0.name
          expect(last_mail.body.multipart?).to be_truthy
          expect(last_mail.body.parts.count).to eq 2
          expect(last_mail.body.parts[0].body).to include(item0.text)
          expect(last_mail.body.parts[1].body).to include(item0.html)
        end

        it "sends item1" do
          visit ezine_member_pages_path(site: site, cid: node1)

          click_link item1.name
          click_link "本配信"
          within "form" do
            click_button "本配信"
          end

          expect(ActionMailer::Base.deliveries.length).to eq 2
          first_mail = ActionMailer::Base.deliveries.first
          expect(first_mail).not_to be_nil
          # expect(mail.from.first).to eq "test@example.jp"
          expect(first_mail.to.first).to eq email1
          expect(first_mail.subject).to eq item1.name
          expect(first_mail.body.multipart?).to be_falsey
          expect(first_mail.body.raw_source).to include(item1.text)

          last_mail = ActionMailer::Base.deliveries.last
          expect(last_mail).not_to be_nil
          expect(last_mail.to.first).to eq email4
          expect(last_mail.subject).to eq item1.name
          expect(last_mail.body.multipart?).to be_truthy
          expect(last_mail.body.parts.count).to eq 2
          expect(last_mail.body.parts[0].body).to include(item1.text)
          expect(last_mail.body.parts[1].body).to include(item1.html)
        end

        it "sends item2" do
          visit ezine_member_pages_path(site: site, cid: node2)

          click_link item2.name
          click_link "本配信"
          within "form" do
            click_button "本配信"
          end

          expect(ActionMailer::Base.deliveries.length).to eq 2
          first_mail = ActionMailer::Base.deliveries.first
          expect(first_mail).not_to be_nil
          # expect(mail.from.first).to eq "test@example.jp"
          expect(first_mail.to.first).to eq email2
          expect(first_mail.subject).to eq item2.name
          expect(first_mail.body.multipart?).to be_falsey
          expect(first_mail.body.raw_source).to include(item2.text)

          last_mail = ActionMailer::Base.deliveries.last
          expect(last_mail).not_to be_nil
          expect(last_mail.to.first).to eq email5
          expect(last_mail.subject).to eq item2.name
          expect(last_mail.body.multipart?).to be_truthy
          expect(last_mail.body.parts.count).to eq 2
          expect(last_mail.body.parts[0].body).to include(item2.text)
          expect(last_mail.body.parts[1].body).to include(item2.html)
        end
      end
    end
  end
end
