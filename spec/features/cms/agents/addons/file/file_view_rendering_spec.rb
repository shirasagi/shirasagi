require 'spec_helper'

describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:node) { create :article_node_page, cur_site: site, cur_user: cms_user }
  let(:filename) { "#{unique_id}.png" }
  let!(:file) { tmp_ss_file contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: cms_user, basename: "#{unique_id}.jpg" }
  let(:button_label) { I18n.t("ss.buttons.upload") }

  before do
    login_cms_user
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
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          click_button I18n.t("ss.buttons.save")
          expect(page).to have_css('.file-view', text: 'logo.png')
        end

        wait_for_cbox_closed do
          page.execute_script("SS_AjaxFile.firesEvents = true;")
          wait_for_event_fired "ss:ajaxFileSelected", selector: "#addon-cms-agents-addons-file .ajax-box" do
            click_on 'logo.png'
          end
        end

        within "#item-form #addon-cms-agents-addons-file" do
          wait_for_cbox_opened do
            click_on button_label
          end
        end

        within "#ajax-box" do
          page.execute_script("SS_AjaxFile.firesEvents = true;")
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          click_button I18n.t("ss.buttons.save")
          expect(page).to have_css('.file-view', text: 'keyvisual.jpg')
          wait_for_cbox_closed do
            wait_for_event_fired "ss:ajaxFileSelected", selector: "#addon-cms-agents-addons-file .ajax-box" do
              click_on 'keyvisual.jpg'
            end
          end
        end

        within ".file-view", text: 'keyvisual.jpg' do
          find(".action-paste").click
        end

        click_on I18n.t("ss.buttons.publish_save")
        click_on I18n.t("ss.buttons.ignore_alert")

        within '#selected-files' do
          expect(page).to have_css(".file-view", text: 'keyvisual.jpg')
          expect(page).to have_css(".file-view.unused", text: 'logo.png')
        end
      end
    end
  end

  context "with cms/file" do
    let!(:file) do
      tmp_ss_file(
        Cms::File, model: "cms/file", user: cms_user, site: site, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:button_label) { I18n.t("cms.file") }
  end
end
