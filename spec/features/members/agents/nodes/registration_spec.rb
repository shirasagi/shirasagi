require 'spec_helper'

describe 'members/agents/nodes/registration', type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node_mypage) { create :member_node_mypage, cur_site: site, layout_id: layout.id, html: '<div id="mypage"></div>' }
  let(:reply_upper_text) do
    %w(
      会員登録ありがとうございました。
      次の URL をクリックし、画面の指示にしたがって会員登録を完了させてください。).join("\n")
  end
  let(:reset_password_upper_text) do
    %w(
      ログインパスワードの再設定用のURLをお送りします。
      次の URL をクリックし、画面の指示にしたがってパスワード再設定を完了させてください。).join("\n")
  end
  let!(:node_registration) do
    create(
      :member_node_registration,
      cur_site: site,
      layout_id: layout.id,
      sender_name: '会員登録',
      sender_email: 'admin@example.jp',
      subject: '登録確認',
      reply_upper_text: reply_upper_text,
      reply_lower_text: '本メールに心当たりのない方は、お手数ですがメールを削除してください。',
      reply_signature: "----\nシラサギ市",
      reset_password_subject: 'パスワード再設定案内',
      reset_password_upper_text: reset_password_upper_text,
      reset_password_lower_text: "本メールに心当たりのない方は、お手数ですがメールを削除してください。",
      reset_password_signature: "----\nシラサギ市")
  end
  let!(:node_login) do
    create(
      :member_node_login,
      cur_site: site,
      layout_id: layout.id,
      redirect_url: node_mypage.url,
      form_auth: "enabled",
      twitter_oauth: "disabled",
      facebook_oauth: "disabled")
  end
  let(:index_path) { node_registration.full_url }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  describe "register new member" do
    let(:name) { unique_id }
    let(:email) { "#{unique_id}@example.jp" }
    let(:kana) { unique_id }
    let(:organization_name) { unique_id }
    let(:job) { unique_id }
    let(:tel) { unique_id }
    let(:postal_code) { unique_id }
    let(:addr) { unique_id }
    let(:sex) { %w(male female).sample }
    let(:era) { "西暦" }
    let(:birthday) { Date.parse("1985-01-01") }
    let(:password) { "abc123" }

    it do
      visit index_path

      within "form" do
        fill_in "item[name]", with: name
        fill_in "item[email]", with: email
        fill_in "item[email_again]", with: email
        fill_in "item[kana]", with: kana
        fill_in "item[organization_name]", with: organization_name
        fill_in "item[job]", with: job
        fill_in "item[tel]", with: tel
        fill_in "item[postal_code]", with: postal_code
        fill_in "item[addr]", with: addr
        choose "item_sex_#{sex}"
        select era, from: "item[in_birth][era]"
        fill_in "item[in_birth][year]", with: birthday.year
        select birthday.month, from: "item[in_birth][month]"
        select birthday.day, from: "item[in_birth][day]"

        click_button "確認画面へ"
      end

      within "form" do
        expect(page.find("input[name='item[name]']", visible: false).value).to eq name
        expect(page.find("input[name='item[email]']", visible: false).value).to eq email
        expect(page.find("input[name='item[kana]']", visible: false).value).to eq kana
        expect(page.find("input[name='item[organization_name]']", visible: false).value).to eq organization_name
        expect(page.find("input[name='item[job]']", visible: false).value).to eq job
        expect(page.find("input[name='item[tel]']", visible: false).value).to eq tel
        expect(page.find("input[name='item[postal_code]']", visible: false).value).to eq postal_code
        expect(page.find("input[name='item[addr]']", visible: false).value).to eq addr
        expect(page.find("input[name='item[sex]']", visible: false).value).to eq sex
        expect(page.find("input[name='item[in_birth][era]']", visible: false).value).to eq "seireki"
        expect(page.find("input[name='item[in_birth][year]']", visible: false).value).to eq birthday.year.to_s
        expect(page.find("input[name='item[in_birth][month]']", visible: false).value).to eq birthday.month.to_s
        expect(page.find("input[name='item[in_birth][day]']", visible: false).value).to eq birthday.day.to_s

        click_button "登録"
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq "admin@example.jp"
      expect(mail.to.first).to eq email
      expect(mail.subject).to eq '登録確認'
      expect(mail.body.multipart?).to be_falsey
      expect(mail.body.raw_source).to include(node_registration.reply_upper_text)
      expect(mail.body.raw_source).to include(node_registration.reply_lower_text)
      expect(mail.body.raw_source).to include(node_registration.reply_signature)

      member = Cms::Member.where(email: email).first
      expect(member.name).to eq name
      expect(member.email).to eq email
      expect(member.state).to eq "temporary"
      expect(member.kana).to eq kana
      expect(member.organization_name).to eq organization_name
      expect(member.job).to eq job
      expect(member.tel).to eq tel
      expect(member.postal_code).to eq postal_code
      expect(member.addr).to eq addr
      expect(member.sex).to eq sex
      expect(member.birthday).to eq birthday

      mail.body.raw_source =~ /(#{Regexp.escape(node_registration.full_url)}[^ \t\r\n]+)/
      url = $1
      expect(url).not_to be_nil
      visit url

      within "form" do
        expect(page.find("input[name='item[name]']", visible: false).value).to eq name
        expect(page).to have_css(".colum dd", text: email)
        fill_in "item[in_password]", with: password
        fill_in "item[in_password_again]", with: password
        expect(page.find("input[name='item[kana]']", visible: false).value).to eq kana
        expect(page.find("input[name='item[tel]']", visible: false).value).to eq tel
        expect(page.find("input[name='item[addr]']", visible: false).value).to eq addr

        click_button "登録"
      end

      member = Cms::Member.where(email: email).first
      expect(member.name).to eq name
      expect(member.email).to eq email
      expect(member.state).to eq "enabled"
      expect(member.kana).to eq kana
      expect(member.tel).to eq tel
      expect(member.addr).to eq addr
      expect(member.sex).to eq sex
      expect(member.birthday).to eq birthday

      click_link "ログイン"

      within "form" do
        fill_in "item[email]", with: email
        fill_in "item[password]", with: password

        click_button "ログイン"
      end

      expect(page). to have_css("div#mypage")
    end
  end

  describe "only fill requried fields" do
    let(:name) { unique_id }
    let(:email) { "#{unique_id}@example.jp" }
    let(:kana) { unique_id }
    let(:postal_code) { unique_id }
    let(:addr) { unique_id }
    let(:sex) { %w(male female).sample }
    let(:era) { "西暦" }
    let(:birthday) { Date.parse("1985-01-01") }

    it do
      visit index_path

      within "form" do
        fill_in "item[name]", with: name
        fill_in "item[email]", with: email
        fill_in "item[email_again]", with: email
        fill_in "item[kana]", with: kana
        fill_in "item[postal_code]", with: postal_code
        fill_in "item[addr]", with: addr
        choose "item_sex_#{sex}"
        select era, from: "item[in_birth][era]"
        fill_in "item[in_birth][year]", with: birthday.year
        select birthday.month, from: "item[in_birth][month]"
        select birthday.day, from: "item[in_birth][day]"

        click_button "確認画面へ"
      end

      within "form" do
        expect(page.find("input[name='item[name]']", visible: false).value).to eq name
        expect(page.find("input[name='item[email]']", visible: false).value).to eq email
        expect(page.find("input[name='item[kana]']", visible: false).value).to eq kana
        expect(page.find("input[name='item[organization_name]']", visible: false).value).to eq ""
        expect(page.find("input[name='item[job]']", visible: false).value).to eq ""
        expect(page.find("input[name='item[tel]']", visible: false).value).to eq ""
        expect(page.find("input[name='item[postal_code]']", visible: false).value).to eq postal_code
        expect(page.find("input[name='item[addr]']", visible: false).value).to eq addr
        expect(page.find("input[name='item[sex]']", visible: false).value).to eq sex
        expect(page.find("input[name='item[in_birth][era]']", visible: false).value).to eq "seireki"
        expect(page.find("input[name='item[in_birth][year]']", visible: false).value).to eq birthday.year.to_s
        expect(page.find("input[name='item[in_birth][month]']", visible: false).value).to eq birthday.month.to_s
        expect(page.find("input[name='item[in_birth][day]']", visible: false).value).to eq birthday.day.to_s

        click_button "登録"
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first

      expect(mail.from.first).to eq "admin@example.jp"
      expect(mail.to.first).to eq email
      expect(mail.subject).to eq '登録確認'
      expect(mail.body.multipart?).to be_falsey
      expect(mail.body.raw_source).to include(node_registration.reply_upper_text)
      expect(mail.body.raw_source).to include(node_registration.reply_lower_text)
      expect(mail.body.raw_source).to include(node_registration.reply_signature)

      member = Cms::Member.where(email: email).first
      expect(member.name).to eq name
      expect(member.email).to eq email
      expect(member.kana).to eq kana
      expect(member.organization_name).to be_nil
      expect(member.job).to be_nil
      expect(member.tel).to be_nil
      expect(member.postal_code).to eq postal_code
      expect(member.addr).to eq addr
      expect(member.sex).to eq sex
      expect(member.birthday).to eq birthday
    end
  end

  describe "name is required" do
    let(:email) { "#{unique_id}@example.jp" }

    it do
      visit index_path

      within "form" do
        fill_in "item[email]", with: email
        fill_in "item[email_again]", with: email

        click_button "確認画面へ"
      end

      within "form div.member-registration-form div.errorExplanation" do
        expect(page).to have_css("li", text: "氏名を入力してください。")
      end

      expect(ActionMailer::Base.deliveries.length).to eq 0
      expect(Cms::Member.where(email: email).count).to eq 0
    end
  end

  describe "email is required" do
    let(:name) { unique_id }
    let(:email) { "#{unique_id}@example.jp" }

    it do
      visit index_path

      within "form" do
        fill_in "item[name]", with: name
        # fill_in "item[email]", with: email
        fill_in "item[email_again]", with: email

        click_button "確認画面へ"
      end

      within "form div.member-registration-form div.errorExplanation" do
        expect(page).to have_css("li", text: "メールアドレスを入力してください。")
      end

      expect(ActionMailer::Base.deliveries.length).to eq 0
      expect(Cms::Member.where(email: email).count).to eq 0
    end

    it do
      visit index_path

      within "form" do
        fill_in "item[name]", with: name
        fill_in "item[email]", with: email
        # fill_in "item[email_again]", with: email

        click_button "確認画面へ"
      end

      within "form div.member-registration-form div.errorExplanation" do
        expect(page).to have_css("li", text: "メールアドレス（確認用）を入力してください。")
      end

      expect(ActionMailer::Base.deliveries.length).to eq 0
      expect(Cms::Member.where(email: email).count).to eq 0
    end
  end

  describe "reset_password" do
    let(:member) { create(:cms_member) }
    let(:index_path) { "#{node_registration.full_url}reset_password/" }
    let(:new_password) { "123abc" }

    it do
      visit index_path

      within "form" do
        fill_in "item[email]", with: member.email
        click_button "送信する"
      end

      within "div.cms-member-registration-notice" do
        expect(page).to have_css("h2", text: "パスワードの再設定案内メールの送付")
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq node_registration.sender_email
      expect(mail.to.first).to eq member.email
      expect(mail.subject).to eq 'パスワード再設定案内'
      expect(mail.body.multipart?).to be_falsey
      expect(mail.body.raw_source).to include(node_registration.reset_password_upper_text)
      expect(mail.body.raw_source).to include(node_registration.reset_password_lower_text)
      expect(mail.body.raw_source).to include(node_registration.reset_password_signature)

      mail.body.raw_source =~ /(#{Regexp.escape(node_registration.full_url)}[^ \t\r\n]+)/
      url = $1
      expect(url).not_to be_nil
      visit url

      within "form" do
        fill_in "item[new_password]", with: new_password
        fill_in "item[new_password_again]", with: new_password
        click_button "パスワードを変更"
      end

      within "div.cms-member-registration-notice" do
        expect(page).to have_css("h2", text: "パスワードの変更")
      end

      member.reload
      expect(member.password).to eq SS::Crypt.crypt(new_password)
    end
  end
end
