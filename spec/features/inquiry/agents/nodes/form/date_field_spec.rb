require 'spec_helper'

describe "inquiry_agents_nodes_form", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node) do
    create(
      :inquiry_node_form,
      cur_site: site,
      layout_id: layout.id,
      inquiry_captcha: 'disabled',
      notice_state: 'enabled',
      notice_content: 'include_answers',
      notice_emails: ['notice@example.jp'],
      from_name: 'admin',
      from_email: 'admin@example.jp',
      reply_state: 'disabled',
      inquiry_show_sent_data: "enabled")
  end

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "date and datetime (use picker)", js: true do
    let(:date) { Time.zone.today }
    let(:date_iso8601) { date.iso8601 }
    let(:date_picker) { I18n.l(date, format: :picker) }
    let(:datetime) { Time.zone.now }
    let(:datetime_iso8601) { datetime.strftime('%FT%H:%M') }
    let(:datetime_picker) { I18n.l(datetime, format: :picker) }

    before do
      node.columns.create! attributes_for(:inquiry_column_date_picker).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_datetime_picker).reverse_merge({cur_site: site})
      node.reload

      Capybara.app_host = "http://#{site.domain}"
    end

    it do
      visit node.url
      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in_date "item[1]", with: date
          fill_in_datetime "item[2]", with: datetime
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'div.inquiry-form.confirm' do
        within 'div.columns' do
          expect(find("[name='item[1]']")['value']).to eq date_iso8601
          expect(find("[name='item[2]']")['value']).to eq datetime_iso8601
          expect(page).to have_css(".column .fields", text: date_picker)
          expect(page).to have_css(".column .fields", text: datetime_picker)
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end
      expect(page).to have_css(".inquiry-sent")
      within ".columns" do
        expect(page).to have_css(".column .fields", text: date_picker)
        expect(page).to have_css(".column .fields", text: datetime_picker)
      end

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq node.id
      expect(answer.data.count).to eq 2
      expect(answer.data[0].value).to eq date_iso8601
      expect(answer.data[0].confirm).to be_nil
      expect(answer.data[1].value).to eq datetime_iso8601
      expect(answer.data[1].confirm).to be_nil

      expect(ActionMailer::Base.deliveries.count).to eq 1

      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq 'admin@example.jp'
        expect(notify_mail.to.first).to eq 'notice@example.jp'
        expect(notify_mail.subject).to eq "[自動通知]#{node.name} - #{site.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include("「#{node.name}」に入力がありました。")
        expect(notify_mail.body.raw_source).to include(inquiry_answer_path(site: site, cid: node, id: answer))
        # inquiry_column_date
        expect(notify_mail.body.raw_source).to include("- " + node.columns[0].name)
        expect(notify_mail.body.raw_source).to include(date_iso8601)
        # inquiry_column_datetime
        expect(notify_mail.body.raw_source).to include("- " + node.columns[1].name)
        expect(notify_mail.body.raw_source).to include(datetime_iso8601)
      end
    end
  end

  context "date and datetime (input tag)" do
    let(:date) { Time.zone.today }
    let(:date_iso8601) { date.iso8601 }
    let(:date_picker) { I18n.l(date, format: :picker) }
    let(:datetime) { Time.zone.now }
    let(:datetime_iso8601) { datetime.strftime('%FT%H:%M') }
    let(:datetime_picker) { I18n.l(datetime, format: :picker) }

    before do
      node.columns.create! attributes_for(:inquiry_column_date_local).reverse_merge({cur_site: site})
      node.columns.create! attributes_for(:inquiry_column_datetime_local).reverse_merge({cur_site: site})
      node.reload

      Capybara.app_host = "http://#{site.domain}"
    end

    it do
      visit node.url
      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: date_iso8601
          fill_in "item[2]", with: datetime_iso8601
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'div.inquiry-form.confirm' do
        within 'div.columns' do
          expect(find("[name='item[1]']")['value']).to eq date_iso8601
          expect(find("[name='item[2]']")['value']).to eq datetime_iso8601
          expect(page).to have_css(".column .fields", text: date_picker)
          expect(page).to have_css(".column .fields", text: datetime_picker)
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end
      expect(page).to have_css(".inquiry-sent")
      within ".columns" do
        expect(page).to have_css(".column .fields", text: date_picker)
        expect(page).to have_css(".column .fields", text: datetime_picker)
      end

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq node.id
      expect(answer.data.count).to eq 2
      expect(answer.data[0].value).to eq date_iso8601
      expect(answer.data[0].confirm).to be_nil
      expect(answer.data[1].value).to eq datetime_iso8601
      expect(answer.data[1].confirm).to be_nil

      expect(ActionMailer::Base.deliveries.count).to eq 1

      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq 'admin@example.jp'
        expect(notify_mail.to.first).to eq 'notice@example.jp'
        expect(notify_mail.subject).to eq "[自動通知]#{node.name} - #{site.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include("「#{node.name}」に入力がありました。")
        expect(notify_mail.body.raw_source).to include(inquiry_answer_path(site: site, cid: node, id: answer))
        # inquiry_column_date
        expect(notify_mail.body.raw_source).to include("- " + node.columns[0].name)
        expect(notify_mail.body.raw_source).to include(date_iso8601)
        # inquiry_column_datetime
        expect(notify_mail.body.raw_source).to include("- " + node.columns[1].name)
        expect(notify_mail.body.raw_source).to include(datetime_iso8601)
      end
    end
  end
end
