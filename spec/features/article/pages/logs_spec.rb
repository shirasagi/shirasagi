require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) do
    create_once :article_node_page, filename: "docs", name: "article",
                group_ids: [cms_group.id], st_form_ids: [form.id]
  end
  let!(:item) { create :article_page, cur_node: node, group_ids: [cms_group.id] }
  let!(:edit_path) { edit_article_page_path site.id, node, item }

  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }

  subject(:logs_path) { history_cms_logs_path site.id }


  context "attach file from upload" do
    before { login_cms_user }

    it "#edit" do
      visit edit_path

      addon = first("#addon-cms-agents-addons-file")
      addon.find('.toggle-head').click if addon.matches_css?(".body-closed")

      within "#addon-cms-agents-addons-file" do
        click_on I18n.t("ss.buttons.upload")
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        wait_for_ajax

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        click_button I18n.t("ss.buttons.attach")
        wait_for_ajax
      end

      within '#selected-files' do
        expect(page).to have_no_css('.name', text: 'keyvisual.jpg')
        expect(page).to have_css('.name', text: 'keyvisual.gif')
      end
      click_button I18n.t("ss.buttons.publish_save")

      visit logs_path
      expect(page).to have_css('.list-item', count: 3)
    end
  end
end
