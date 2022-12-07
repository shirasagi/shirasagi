require 'spec_helper'

describe "inquiry_form", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group) { cms_group }
  let!(:group1) do
    create(
      :cms_group, name: "#{group.name}/#{unique_id}",
      contact_groups: [{ name: unique_id, contact_email: unique_email, main_state: "main" }])
  end
  let!(:group2) do
    create(
      :cms_group, name: "#{group.name}/#{unique_id}",
      contact_groups: [{ name: unique_id, contact_email: unique_email, main_state: "main" }])
  end

  let(:layout) { create_cms_layout page_name: true }
  let!(:inquiry_form) do
    create(
      :inquiry_node_form, cur_site: site, layout: layout, state: "public", inquiry_captcha: "disabled",
      notice_state: "enabled", notice_content: "link_only", notice_email: unique_email,
      from_name: unique_id, from_email: unique_email, reply_state: "disabled", aggregation_state: "disabled",
      group_ids: [ group.id ]
    )
  end
  let!(:article_node) { create :article_node_page, cur_site: site, layout: layout }
  let!(:article_page) { create :article_page, cur_site: site, cur_node: article_node, layout: layout, contact_state: "show" }
  let(:name) { ss_japanese_text }

  before do
    site.inquiry_form = inquiry_form
    site.save!

    group.contact_groups = [{ name: unique_id, contact_email: unique_email, main_state: "main" }]
    group.save!
    expect(group.contact_email).to be_present

    inquiry_form.columns.create! attributes_for(:inquiry_column_name).reverse_merge(cur_site: site)
  end

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "without group and page" do
    it do
      visit inquiry_form.full_url
      expect(page).to have_css("#ss-page-name", text: inquiry_form.name)

      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: name
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find('#item_1')['value']).to eq name
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq inquiry_form.id
      expect(answer.data.count).to eq 1
      expect(answer.data[0].value).to eq name
      expect(answer.data[0].confirm).to be_nil
      expect(answer.group_ids).to eq inquiry_form.group_ids

      expect(ActionMailer::Base.deliveries.count).to eq 1

      ActionMailer::Base.deliveries.first.tap do |mail|
        expect(mail.from.first).to eq inquiry_form.from_email
        expect(mail.to.first).to eq inquiry_form.notice_email
        expect(mail.subject).to eq "[自動通知]#{inquiry_form.name} - #{site.name}"
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include("「#{inquiry_form.name}」に入力がありました。")
        answer_url = Rails.application.routes.url_helpers.inquiry_answer_url(
          protocol: "http", host: site.domain, site: site, cid: inquiry_form, id: answer
        )
        expect(mail.body.raw_source).to include(answer_url)
        expect(mail.body.raw_source).not_to include(name)
      end
    end
  end

  context "with group and page" do
    before do
      article_page.contact_group = group1
      article_page.save!
    end

    it do
      visit inquiry_form.full_url + "?" + { group: group1.id, page: article_page.id }.to_query
      expect(page).to have_css("#ss-page-name", text: group1.section_name + " " + inquiry_form.name)

      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: name
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find('#item_1')['value']).to eq name
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq inquiry_form.id
      expect(answer.data.count).to eq 1
      expect(answer.data[0].value).to eq name
      expect(answer.data[0].confirm).to be_nil
      expect(answer.group_ids).to eq [ group1.id ]

      expect(ActionMailer::Base.deliveries.count).to eq 1

      ActionMailer::Base.deliveries.first.tap do |mail|
        expect(mail.from.first).to eq inquiry_form.from_email
        expect(mail.to.first).to eq group1.contact_email
        expect(mail.subject).to eq "[自動通知]#{inquiry_form.name} - #{site.name}"
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include("「#{inquiry_form.name}」に入力がありました。")
        answer_url = Rails.application.routes.url_helpers.inquiry_answer_url(
          protocol: "http", host: site.domain, site: site, cid: inquiry_form, id: answer
        )
        expect(mail.body.raw_source).to include(answer_url)
        expect(mail.body.raw_source).not_to include(name)
      end
    end
  end

  context "with closed page" do
    before do
      article_page.contact_group = group1
      article_page.state = "closed"
      article_page.save!
    end

    it do
      visit inquiry_form.full_url + "?" + { group: group1.id, page: article_page.id }.to_query
      expect { page.reset! }.to raise_error(RuntimeError, "404")
    end
  end

  context "with disabled group" do
    before do
      group1.expiration_date = 1.second.ago
      group1.save!

      article_page.contact_group = group1
      article_page.save!
    end

    it do
      visit inquiry_form.full_url + "?" + { group: group1.id, page: article_page.id }.to_query
      expect { page.reset! }.to raise_error(RuntimeError, "404")
    end
  end

  context "with group and page on none site's inquiry form" do
    before do
      site.inquiry_form = nil
      site.save!

      article_page.contact_group = group1
      article_page.save!
    end

    it do
      visit inquiry_form.full_url + "?" + { group: group1.id, page: article_page.id }.to_query
      expect { page.reset! }.to raise_error(RuntimeError, "404")
    end
  end

  context "without group's contact_email" do
    before do
      group1.contact_groups = nil
      group1.save!

      article_page.contact_group = group1
      article_page.save!
    end

    it do
      visit inquiry_form.full_url + "?" + { group: group1.id, page: article_page.id }.to_query
      expect { page.reset! }.to raise_error(RuntimeError, "404")
    end
  end
end
