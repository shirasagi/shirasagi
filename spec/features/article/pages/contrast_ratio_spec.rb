require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_user: user, cur_site: site }
  let!(:file1) { create :cms_temp_file, cur_user: user, site: site, node: node, name: unique_id }
  let!(:file2) { create :cms_temp_file, cur_user: user, site: site, node: node, name: unique_id }

  before { login_user user }

  describe "contrast ratio check" do
    context "on show" do
      context "on cms/addon/file" do
        let!(:item) { create :article_page, cur_user: user, cur_site: site, cur_node: node, file_ids: [ file1.id ] }

        context "with already bound file" do
          it do
            visit article_page_path(site: site, cid: node, id: item)

            within "#addon-cms-agents-addons-file" do
              first(".file-view[data-file-id='#{file1.id}'] a").click
            end
            wait_for_cbox do
              within "#ss-file-view" do
                fill_in "foreground-color", with: "#ffffff" + "\n"
                fill_in "background-color", with: "#ffffff" + "\n"
                click_on I18n.t("ss.buttons.calculate")
                expect(page).to have_css(".contrast-ratio", text: "1.0")
              end
            end
          end
        end
      end

      context "on cms/addon/thumb" do
        let!(:item) { create :article_page, cur_user: user, cur_site: site, cur_node: node, thumb_id: file1.id }

        it do
          visit article_page_path(site: site, cid: node, id: item)

          within "#addon-cms-agents-addons-thumb" do
            first(".file-view[data-file-id='#{file1.id}'] a").click
          end
          wait_for_cbox do
            within "#ss-file-view" do
              fill_in "foreground-color", with: "#ffffff" + "\n"
              fill_in "background-color", with: "#ffffff" + "\n"
              click_on I18n.t("ss.buttons.calculate")
              expect(page).to have_css(".contrast-ratio", text: "1.0")
            end
          end
        end
      end

      context "on cms/addon/form/page" do
        let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
        let!(:column1) do
          create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 1, file_type: "image")
        end
        let!(:column2) do
          create(:cms_column_free, cur_site: site, cur_form: form, order: 2)
        end
        let!(:item) { create :article_page, cur_user: user, cur_site: site, cur_node: node }

        before do
          node.st_form_ids = [ form.id ]
          node.save!

          item.form = form
          item.column_values = [
            column1.value_type.new(column: column1, file_id: file1.id, file_label: file1.humanized_name),
            column2.value_type.new(column: column2, value: unique_id * 2, file_ids: [ file2.id ])
          ]
          item.save!
        end

        it do
          visit article_page_path(site: site, cid: node, id: item)

          within "#addon-cms-agents-addons-form-page" do
            first(".file-view[data-file-id='#{file1.id}'] a").click
          end
          wait_for_cbox do
            within "#ss-file-view" do
              fill_in "foreground-color", with: "#ffffff" + "\n"
              fill_in "background-color", with: "#ffffff" + "\n"
              click_on I18n.t("ss.buttons.calculate")
              expect(page).to have_css(".contrast-ratio", text: "1.0")
            end
          end

          visit article_page_path(site: site, cid: node, id: item)
          within "#addon-cms-agents-addons-form-page" do
            first(".file-view[data-file-id='#{file2.id}'] a").click
          end
          wait_for_cbox do
            within "#ss-file-view" do
              fill_in "foreground-color", with: "#ffffff" + "\n"
              fill_in "background-color", with: "#ffffff" + "\n"
              click_on I18n.t("ss.buttons.calculate")
              expect(page).to have_css(".contrast-ratio", text: "1.0")
            end
          end
        end
      end
    end

    context "on edit" do
      context "on cms/addon/file" do
        let!(:item) { create :article_page, cur_user: user, cur_site: site, cur_node: node, file_ids: [ file1.id ] }

        context "with already bound file" do
          it do
            visit edit_article_page_path(site: site, cid: node, id: item)

            within "#addon-cms-agents-addons-file" do
              first(".file-view[data-file-id='#{file1.id}'] a").click
            end
            wait_for_cbox do
              within "#ss-file-view" do
                fill_in "foreground-color", with: "#ffffff" + "\n"
                fill_in "background-color", with: "#ffffff" + "\n"
                click_on I18n.t("ss.buttons.calculate")
                expect(page).to have_css(".contrast-ratio", text: "1.0")
              end
            end
          end
        end

        context "with newly added file" do
          it do
            visit edit_article_page_path(site: site, cid: node, id: item)

            within "#addon-cms-agents-addons-file" do
              click_on I18n.t("ss.buttons.upload")
            end
            wait_for_cbox do
              within ".index" do
                first(".file-view[data-file-id='#{file2.id}'] a").click
              end
            end

            within "#addon-cms-agents-addons-file" do
              first(".file-view[data-file-id='#{file2.id}'] a").click
            end
            wait_for_cbox do
              within "#ss-file-view" do
                fill_in "foreground-color", with: "#ffffff" + "\n"
                fill_in "background-color", with: "#ffffff" + "\n"
                click_on I18n.t("ss.buttons.calculate")
                expect(page).to have_css(".contrast-ratio", text: "1.0")
              end
            end
          end
        end
      end

      context "on cms/addon/form/page" do
        let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
        let!(:column1) do
          create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 1, file_type: "image")
        end
        let!(:column2) do
          create(:cms_column_free, cur_site: site, cur_form: form, order: 2)
        end
        let!(:item) { create :article_page, cur_user: user, cur_site: site, cur_node: node }

        before do
          node.st_form_ids = [ form.id ]
          node.save!

          item.form = form
          item.column_values = [
            column1.value_type.new(column: column1, file_id: file1.id, file_label: file1.humanized_name),
            column2.value_type.new(column: column2, value: unique_id * 2, file_ids: [ file2.id ])
          ]
          item.save!
        end

        context "with already bound file" do
          it do
            visit edit_article_page_path(site: site, cid: node, id: item)

            within "#addon-cms-agents-addons-form-page" do
              first(".file-view[data-file-id='#{file1.id}'] a").click
            end
            wait_for_cbox do
              within "#ss-file-view" do
                fill_in "foreground-color", with: "#ffffff" + "\n"
                fill_in "background-color", with: "#ffffff" + "\n"
                click_on I18n.t("ss.buttons.calculate")
                expect(page).to have_css(".contrast-ratio", text: "1.0")
              end
            end

            visit article_page_path(site: site, cid: node, id: item)
            within "#addon-cms-agents-addons-form-page" do
              first(".file-view[data-file-id='#{file2.id}'] a").click
            end
            wait_for_cbox do
              within "#ss-file-view" do
                fill_in "foreground-color", with: "#ffffff" + "\n"
                fill_in "background-color", with: "#ffffff" + "\n"
                click_on I18n.t("ss.buttons.calculate")
                expect(page).to have_css(".contrast-ratio", text: "1.0")
              end
            end
          end
        end

        context "with newly added file" do
          let!(:file3) { create :cms_temp_file, cur_user: user, site: site, name: unique_id }
          let!(:file4) { create :cms_temp_file, cur_user: user, site: site, name: unique_id }

          it do
            visit edit_article_page_path(site: site, cid: node, id: item)
            within "#addon-cms-agents-addons-form-page" do
              within ".column-value-cms-column-fileupload" do
                click_on I18n.t("ss.buttons.upload")
              end
            end
            wait_for_cbox do
              within ".index" do
                first(".file-view[data-file-id='#{file3.id}'] a").click
              end
            end

            within "#addon-cms-agents-addons-form-page" do
              first(".file-view[data-file-id='#{file3.id}'] a").click
            end
            wait_for_cbox do
              within "#ss-file-view" do
                fill_in "foreground-color", with: "#ffffff" + "\n"
                fill_in "background-color", with: "#ffffff" + "\n"
                click_on I18n.t("ss.buttons.calculate")
                expect(page).to have_css(".contrast-ratio", text: "1.0")
              end
            end

            visit edit_article_page_path(site: site, cid: node, id: item)
            within "#addon-cms-agents-addons-form-page" do
              within ".column-value-cms-column-free" do
                click_on I18n.t("ss.buttons.upload")
              end
            end
            wait_for_cbox do
              within ".index" do
                first(".file-view[data-file-id='#{file4.id}'] a").click
              end
            end

            within "#addon-cms-agents-addons-form-page" do
              first(".file-view[data-file-id='#{file4.id}'] a").click
            end
            wait_for_cbox do
              within "#ss-file-view" do
                fill_in "foreground-color", with: "#ffffff" + "\n"
                fill_in "background-color", with: "#ffffff" + "\n"
                click_on I18n.t("ss.buttons.calculate")
                expect(page).to have_css(".contrast-ratio", text: "1.0")
              end
            end
          end
        end
      end
    end
  end
end
