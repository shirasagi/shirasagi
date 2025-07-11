require 'spec_helper'

describe "inquiry_agents_nodes_form", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) do
    create(
      :inquiry_node_form,
      cur_site: site,
      layout_id: layout.id,
      inquiry_captcha: 'disabled',
      notice_state: notice_state,
      notice_emails: notice_emails,
      from_name: from_name,
      from_email: from_email)
  end
  let!(:from_name) { unique_id }
  let!(:from_email) { "#{unique_id}@example.jp" }
  let!(:name) { unique_id }

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site})
    node.reload

    Capybara.app_host = "http://#{site.domain}"
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "notice_state disabled" do
    let!(:notice_state) { "disabled" }
    let!(:notice_emails) { ["#{unique_id}@example.jp"] }

    it do
      visit node.url
      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: name
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'div.inquiry-form.confirm' do
        within 'div.columns' do
          expect(find("[name='item[1]']")['value']).to eq name
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end
      expect(page).to have_css(".inquiry-sent")

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq node.id
      expect(answer.data.count).to eq 1
      expect(answer.data[0].value).to eq name
      expect(answer.data[0].confirm).to be_nil

      expect(ActionMailer::Base.deliveries.count).to eq 0
    end
  end

  context "single notice_emails" do
    let!(:notice_state) { "enabled" }
    let!(:notice_emails) { ["#{unique_id}@example.jp"] }

    it do
      visit node.url
      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: name
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'div.inquiry-form.confirm' do
        within 'div.columns' do
          expect(find("[name='item[1]']")['value']).to eq name
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end
      expect(page).to have_css(".inquiry-sent")

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq node.id
      expect(answer.data.count).to eq 1
      expect(answer.data[0].value).to eq name
      expect(answer.data[0].confirm).to be_nil

      expect(ActionMailer::Base.deliveries.count).to eq 1
      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq from_email
        expect(notify_mail.to.to_a).to eq notice_emails
        expect(notify_mail.subject).to eq "[自動通知]#{node.name} - #{site.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include("「#{node.name}」に入力がありました。")
        expect(notify_mail.body.raw_source).to include(inquiry_answer_path(site: site, cid: node, id: answer))
      end
    end
  end

  context "multiple notice_emails" do
    let!(:notice_state) { "enabled" }
    let!(:notice_emails) do
      [
        "sample1@example.jp",
        "sample2@example.jp",
        "sample3@example.jp",
      ]
    end

    it do
      visit node.url
      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: name
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'div.inquiry-form.confirm' do
        within 'div.columns' do
          expect(find("[name='item[1]']")['value']).to eq name
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end
      expect(page).to have_css(".inquiry-sent")

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq node.id
      expect(answer.data.count).to eq 1
      expect(answer.data[0].value).to eq name
      expect(answer.data[0].confirm).to be_nil

      expect(ActionMailer::Base.deliveries.count).to eq 3

      notify_mails = ActionMailer::Base.deliveries.to_a.sort_by { |mail| mail.to.first }
      notify_mails.each_with_index do |notify_mail, idx|
        expect(notify_mail.from.first).to eq from_email
        expect(notify_mail.to.to_a).to eq [notice_emails[idx]]
        expect(notify_mail.subject).to eq "[自動通知]#{node.name} - #{site.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include("「#{node.name}」に入力がありました。")
        expect(notify_mail.body.raw_source).to include(inquiry_answer_path(site: site, cid: node, id: answer))
      end
    end
  end
end
