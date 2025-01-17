require 'spec_helper'

describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:node) { create :article_node_page, cur_site: site, cur_user: cms_user }
  let(:filename) { "#{unique_id}.png" }
  let!(:file_1) { tmp_ss_file contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: cms_user, basename: "#{unique_id}.jpg" }
  let!(:file_2) do
    tmp_ss_file contents: "#{Rails.root}/spec/fixtures/ss/keyvisual.jpg", user: cms_user, basename: "#{unique_id}.jpg"
  end
  let!(:item) { create :article_page, cur_site: site, cur_user: cms_user, cur_node: node, file_ids: [ file_1.id ] }
  let(:button_label) { I18n.t("ss.buttons.upload") }

  before do
    login_cms_user
    item.update(contains_urls: [file_1.url])
  end

  context "with article/page" do

    describe "index" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        fill_in "item[name]", with: "sample"
        click_on I18n.t("ss.links.input")
        fill_in "item[basename]", with: "sample"

        within "#item-form #addon-cms-agents-addons-file" do
          wait_for_cbox_opened do
            click_on button_label
          end
        end

        within "#ajax-box" do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          click_button I18n.t("ss.buttons.save")
          expect(page).to have_css('.file-view', text: 'keyvisual.jpg')
          wait_for_cbox_closed do
            wait_for_event_fired "ss:ajaxFileSelected", selector: "#addon-cms-agents-addons-file .ajax-box" do
              click_on 'keyvisual.jpg'
            end
          end
        end

        wait_for_cbox_closed do
          wait_for_event_fired "ss:ajaxFileSelected", selector: "#addon-cms-agents-addons-file .ajax-box" do
            click_on 'keyvisual.jpg'
          end
        end

        within ".file-view", text: 'keyvisual.jpg' do
          find(".action-paste").click
        end

        click_on I18n.t("ss.buttons.publish_save")
        click_on I18n.t("ss.buttons.ignore_alert")

        within '#selected-files' do
          expect(page).to have_css('.name', text: file_1.filename)
        end

        expect(page).to have_css(".file-view", text: file_1.filename)
        expect(page).to have_css(".file-view.unused", text: file_2.name)
      end
    end
  end

  context "with cms/temp_file" do
    let!(:file) do
      tmp_ss_file(
        Cms::TempFile, user: cms_user, site: site, node: node, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:button_label) { I18n.t("ss.buttons.upload") }
  end
end
