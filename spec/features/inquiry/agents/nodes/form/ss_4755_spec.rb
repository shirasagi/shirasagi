require 'spec_helper'

describe "inquiry_agents_nodes_form", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group0) { cms_group }
  let!(:layout) { create_cms_layout(page_name: true) }
  let(:inquiry_sent) { "お問い合わせを受け付けました。" }
  let!(:inquiry_form) do
    create(
      :inquiry_node_form, cur_site: site, layout: layout, inquiry_sent_html: "<p>#{inquiry_sent}</p>",
      inquiry_captcha: 'disabled', notice_state: 'disabled', reply_state: 'disabled',
      group_ids: [ group0.id ]
    )
  end

  let!(:group1) do
    # group1 is sub group of group0
    create(
      :cms_group, name: "#{group0.name}/#{unique_id}",
      contact_groups: [{ name: unique_id, contact_email: unique_email, main_state: "main" }])
  end

  let!(:article_node) { create :article_node_page, cur_site: site, layout: layout, group_ids: [ group1.id ] }
  let!(:article_page) do
    create(
      :article_page, cur_site: site, cur_node: article_node, layout: layout,
      contact_state: "show", contact_group: group1, contact_group_contact: group1.contact_groups.first,
      group_ids: [ group1.id ])
  end

  before do
    inquiry_form.columns.create! attributes_for(:inquiry_column_name).reverse_merge(cur_site: site)
    inquiry_form.reload

    # to reproduce issues, we need the public view html of "inquiry_form"
    # So run node generation job before the test.
    # Comment out the following 2 lines to see the test success.
    Cms::Node::GenerateJob.bind(site_id: site, node_id: inquiry_form).perform_now
    expect(::File.size("#{inquiry_form.path}/index.html")).to be > 0
  end

  context "ss-4755" do
    let(:answer1) { unique_id }
    let(:answer2) { unique_id }
    it do
      login_cms_user

      # set Cms::Site#inquiry_form_id
      visit cms_site_path(site: site)
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        ensure_addon_opened "#addon-ss-agents-addons-inquiry_setting"
        within "#addon-ss-agents-addons-inquiry_setting" do
          select inquiry_form.name, from: "item[inquiry_form_id]"
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      # after set Cms::Site#inquiry_form_id, we need to re-generate public view html of "article_page" to reflect the setting
      Cms::Page::GenerateJob.bind(site_id: site, node_id: article_node).perform_now
      Cms::Node::GenerateJob.bind(site_id: site, node_id: inquiry_form).perform_now

      visit article_page.full_url
      within ".inquiry-form" do
        click_on I18n.t("contact.view.inquiry_form")
      end

      # page's title should contain group1.section_name
      expect(page).to have_css("#ss-page-name", text: "#{group1.section_name} #{inquiry_form.name}")
      within 'div.inquiry-form' do
        # page's form should contain group id and page id
        expect(first('[name="group"]').value).to eq article_page.contact_group.id.to_s
        expect(first('[name="page"]').value).to eq article_page.id.to_s
        within 'div.columns' do
          fill_in "item[1]", with: answer1
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find("[name='item[1]']")['value']).to eq answer1
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end
      expect(page).to have_content(inquiry_sent)

      expect(Inquiry::Answer.site(site).count).to eq 1
      answer = Inquiry::Answer.first
      expect(answer.node_id).to eq inquiry_form.id
      expect(answer.source_url).to be_blank
      expect(answer.source_name).to be_blank
      expect(answer.closed).to be_blank
      expect(answer.state).to eq "open"
      expect(answer.comment).to be_blank
      expect(answer.inquiry_page_url).to eq article_page.url
      expect(answer.inquiry_page_name).to eq article_page.name
      expect(answer.member).to be_nil
      expect(answer.data.count).to eq 1
      expect(answer.data[0].value).to eq answer1
      expect(answer.data[0].confirm).to be_blank
      expect(answer.group_ids).to eq [ group1.id ]
      expect(answer.group_ids).to eq article_page.group_ids

      expect(ActionMailer::Base.deliveries.count).to eq 0


      # Submit the 2nd answer to confirm

      visit article_page.full_url
      within ".inquiry-form" do
        click_on I18n.t("contact.view.inquiry_form")
      end

      # page's title should contain group1.section_name
      expect(page).to have_css("#ss-page-name", text: "#{group1.section_name} #{inquiry_form.name}")
      within 'div.inquiry-form' do
        # page's form should contain group id and page id
        expect(first('[name="group"]').value).to eq article_page.contact_group.id.to_s
        expect(first('[name="page"]').value).to eq article_page.id.to_s
        within 'div.columns' do
          fill_in "item[1]", with: answer2
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find("[name='item[1]']")['value']).to eq answer2
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end
      expect(page).to have_content(inquiry_sent)

      expect(Inquiry::Answer.site(site).count).to eq 2
      answer = Inquiry::Answer.last
      expect(answer.node_id).to eq inquiry_form.id
      expect(answer.source_url).to be_blank
      expect(answer.source_name).to be_blank
      expect(answer.closed).to be_blank
      expect(answer.state).to eq "open"
      expect(answer.comment).to be_blank
      expect(answer.inquiry_page_url).to eq article_page.url
      expect(answer.inquiry_page_name).to eq article_page.name
      expect(answer.member).to be_nil
      expect(answer.data.count).to eq 1
      expect(answer.data[0].value).to eq answer2
      expect(answer.data[0].confirm).to be_blank
      expect(answer.group_ids).to eq [ group1.id ]
      expect(answer.group_ids).to eq article_page.group_ids

      expect(ActionMailer::Base.deliveries.count).to eq 0
    end
  end
end
