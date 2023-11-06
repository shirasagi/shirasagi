require 'spec_helper'

describe "inquiry_form", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:group) do
    contact_groups = [
      {
        name: "main",
        contact_group_name: "contact_group_name-#{unique_id}",
        contact_charge: "contact_charge-#{unique_id}",
        contact_tel: unique_tel,
        contact_fax: unique_tel,
        contact_email: unique_email,
        contact_link_url: "/#{unique_id}",
        contact_link_name: "link_name-#{unique_id}",
        main_state: "main"
      },
      {
        name: "alt",
        contact_group_name: "contact_group_name-#{unique_id}",
        contact_charge: "contact_charge-#{unique_id}",
        contact_tel: unique_tel,
        contact_fax: unique_tel,
        contact_email: unique_email,
        contact_link_url: "/#{unique_id}",
        contact_link_name: "link_name-#{unique_id}",
        main_state: ""
      }
    ]
    create(:contact_group, name: "#{cms_group.name}/contact_group", contact_groups: contact_groups)
  end
  let(:main_contact) { group.contact_groups.where(name: "main").first }
  let(:alt_contact) { group.contact_groups.where(name: "alt").first }
  let!(:node) do
    create :inquiry_node_form, cur_site: site, inquiry_captcha: 'disabled', group_ids: [ cms_group.id ]
  end
  let!(:layout) { create_cms_layout }
  let!(:article_node) { create :article_node_page, layout: layout, filename: "node" }
  let!(:article) do
    create(
      :article_page, cur_node: article_node, layout: layout, contact_group: group, contact_group_contact_id: alt_contact.id)
  end
  let(:edit_site_path) { edit_cms_site_path site.id }
  let(:edit_article_path) { edit_article_page_path site.id, article_node, article }

  let(:name) { unique_id }
  let(:email) { "#{unique_id}@example.jp" }
  let(:name_column) { node.columns[0] }
  let(:email_column) { node.columns[2] }

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site}).merge(question: 'enabled')
    node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site}).merge(question: 'enabled')
    node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site})
    node.reload
  end

  after { ActionMailer::Base.deliveries.clear }

  context "set inquiry form" do
    before { login_cms_user }

    it do
      visit article.url
      expect(page).to have_no_content I18n.t("contact.view.inquiry_form")
      expect(page).to have_css(".tel", text: alt_contact.contact_tel)
      expect(page).to have_css(".email", text: alt_contact.contact_email)

      visit edit_site_path
      within "form#item-form" do
        ensure_addon_opened "#addon-ss-agents-addons-inquiry_setting"
        select node.name, from: "item_inquiry_form_id"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit edit_article_path
      within "form#item-form" do
        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit article.url
      expect(page).to have_link(I18n.t("contact.view.inquiry_form"), href: "#{node.url}?group=#{group.id}&page=#{article.id}")
      expect(page).to have_css(".tel", text: alt_contact.contact_tel)
      expect(page).to have_css(".email", text: alt_contact.contact_email)

      click_on I18n.t("contact.view.inquiry_form")
      expect(current_path).to eq node.url
      within "form" do
        fill_in "item[1]", with: name
        fill_in "item[3]", with: email
        fill_in "item[3_confirm]", with: email
        click_on I18n.t("inquiry.confirm")
      end
      within "form" do
        click_on I18n.t("inquiry.submit")
      end
      expect(page).to have_content(ApplicationController.helpers.sanitize(node.inquiry_sent_html, tags: []))

      expect(Inquiry::Answer.all.count).to eq 1
      Inquiry::Answer.all.first.tap do |answer|
        expect(answer.site_id).to eq site.id
        expect(answer.node_id).to eq node.id
        expect(answer.remote_addr).to be_present
        expect(answer.user_agent).to be_present
        expect(answer.source_url).to be_blank
        expect(answer.source_name).to be_blank
        expect(answer.closed).to be_blank
        expect(answer.state).to eq "open"
        expect(answer.comment).to be_blank
        expect(answer.inquiry_page_url).to eq article.url
        expect(answer.inquiry_page_name).to eq article.name
        expect(answer.member_id).to be_blank
        expect(answer.data.where(column_id: name_column.id).first.value).to eq name
        expect(answer.data.where(column_id: email_column.id).first.value).to eq email
        expect(answer.group_ids).to eq [ group.id ]
        expect(answer.group_ids).not_to eq node.group_ids
      end
    end

    context "when site's inquiry-form is closed" do
      before do
        site.inquiry_form = node
        site.save!

        node.state = "closed"
        node.save!

        ::FileUtils.rm_f(article.path)
      end

      it do
        visit article.url
        expect(page).to have_no_content I18n.t("contact.view.inquiry_form")
        expect(page).to have_css(".tel", text: alt_contact.contact_tel)
        expect(page).to have_css(".email", text: alt_contact.contact_email)
      end
    end

    context "when contact group's main email is blank" do
      # グループに主メールアドレスが設定されているかどうかで、お問い合わせフォームのリンクを表示するかどうかを切り替えている。
      # 分かりずらい仕様だと思うので、将来のどこかのタイミングで、別のスイッチを儲けた方が良さそう。
      before do
        site.inquiry_form = node
        site.save!

        main_contact.update(contact_email: nil)

        group.reload
        group.touch
        group.save!

        expect(group.contact_email).to be_blank

        ::FileUtils.rm_f(article.path)
      end

      it do
        visit article.url
        expect(page).to have_no_content I18n.t("contact.view.inquiry_form")
        expect(page).to have_css(".tel", text: alt_contact.contact_tel)
        expect(page).to have_css(".email", text: alt_contact.contact_email)
      end
    end
  end
end
