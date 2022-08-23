require 'spec_helper'
require 'fileutils'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create :article_node_page, filename: "docs", name: "article", group_ids: [cms_group.id] }
  let!(:item) { create :article_page, cur_node: node, group_ids: [cms_group.id] }
  let!(:show_path) { article_page_path site.id, node, item }
  let!(:edit_path) { edit_article_page_path site.id, node, item }

  let(:before_csv) { "#{Rails.root}/spec/fixtures/ss/replace_file/before_csv.csv" }
  let(:after_csv) { "#{Rails.root}/spec/fixtures/ss/replace_file/after_csv.csv" }

  context "replace file" do
    context "in cms addon file" do
      before { login_cms_user }

      it "restore" do
        visit edit_path

        # original file upload
        wait_for_js_ready
        within "form#item-form" do
          within "#addon-cms-agents-addons-file" do
            wait_cbox_open do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end

        wait_for_cbox do
          attach_file "item[in_files][]", before_csv
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end
        within "#addon-cms-agents-addons-file" do
          expect(page).to have_css('.file-view', text: ::File.basename(before_csv))
        end
        click_on I18n.t("ss.buttons.publish_save")
        wait_for_notice I18n.t('ss.notice.saved')

        5.times.each do |index|
          page.execute_script("SS.clearNotice();")
          wait_for_js_ready

          # open replace file dialog
          within "#addon-cms-agents-addons-file" do
            if index == 0
              expect(page).to have_css('.file-view', text: ::File.basename(before_csv))
            else
              expect(page).to have_css('.file-view', text: "replaced")
            end

            click_on I18n.t("ss.buttons.replace_file")
          end

          # upload file and confirmation
          wait_for_js_ready
          wait_for_cbox do
            expect(page).to have_css("input[type='submit'][value='#{I18n.t('inquiry.confirm')}']")
            attach_file "item[in_file]", after_csv
            click_button I18n.t('inquiry.confirm')

            expect(page).to have_css('.file-view.before')
            expect(page).to have_css('.file-view.after', text: ::File.basename(after_csv, ".*"))

            # replace file
            fill_in "item[name]", with: "replaced"
            click_button I18n.t('ss.buttons.replace_save')
          end
          wait_for_notice I18n.t('ss.notice.replace_saved')
        end

        replaced_page = item.class.find(item.id)
        replaced_file = replaced_page.attached_files.first

        # history files
        expect(replaced_file.history_files.size).to eq 5
        history_file = replaced_file.history_files.last

        expect(history_file.filename).to eq ::File.basename(before_csv)
        expect(history_file.name).to eq ::File.basename(before_csv)
        expect(history_file.state).to eq "closed"
        expect(Fs.cmp(history_file.path, before_csv)).to be true

        # show history files and restore
        wait_for_js_ready
        within "#addon-cms-agents-addons-file" do
          expect(page).to have_css('.file-view', text: "replaced")
          wait_cbox_open do
            click_on I18n.t("ss.buttons.replace_file")
          end
        end

        wait_for_cbox do
          wait_for_js_ready
          click_on I18n.t("ss.buttons.file_histories")

          within "table.index tbody" do
            expect(all("tr").size).to eq 5
            within all("tr").last do
              expect(page).to have_css("td", text: "before_csv.csv")
              expect(page).to have_css("a", text: I18n.t('history.buttons.restore'))
              expect(page).to have_css("a", text: I18n.t("ss.links.download"))
              expect(page).to have_css("a", text: I18n.t("ss.buttons.delete"))

              page.accept_confirm do
                click_on I18n.t('history.buttons.restore')
              end
            end
          end
        end
        wait_for_notice I18n.t('history.notice.restored')

        replaced_page = item.class.find(item.id)
        replaced_file = replaced_page.attached_files.first
        expect(replaced_file.history_files.size).to eq 6

        expect(replaced_file.filename).to eq "before_csv.csv"
        expect(replaced_file.name).to eq "before_csv.csv"
        expect(replaced_file.state).to eq "public"
        expect(Fs.cmp(replaced_file.path, before_csv)).to be true
      end

      it "destroy" do
        visit edit_path

        # original file upload
        wait_for_js_ready
        within "form#item-form" do
          within "#addon-cms-agents-addons-file" do
            wait_cbox_open do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end

        wait_for_cbox do
          wait_for_js_ready
          attach_file "item[in_files][]", before_csv
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end
        within "#addon-cms-agents-addons-file" do
          expect(page).to have_css('.file-view', text: ::File.basename(before_csv))
        end
        click_on I18n.t("ss.buttons.publish_save")
        wait_for_notice I18n.t('ss.notice.saved')

        3.times.each do |index|
          wait_for_js_ready
          page.execute_script("SS.clearNotice();")

          # open replace file dialog
          within "#addon-cms-agents-addons-file" do
            if index == 0
              expect(page).to have_css('.file-view', text: ::File.basename(before_csv))
            else
              expect(page).to have_css('.file-view', text: "replaced")
            end

            click_on I18n.t("ss.buttons.replace_file")
          end

          # upload file and confirmation
          wait_for_cbox do
            wait_for_js_ready
            expect(page).to have_css("input[type='submit'][value='#{I18n.t('inquiry.confirm')}']")
            attach_file "item[in_file]", after_csv
            click_button I18n.t('inquiry.confirm')

            expect(page).to have_css('.file-view.before')
            expect(page).to have_css('.file-view.after', text: ::File.basename(after_csv, ".*"))

            # replace file
            fill_in "item[name]", with: "replaced"
            click_button I18n.t('ss.buttons.replace_save')
          end
          wait_for_notice I18n.t('ss.notice.replace_saved')
        end

        # show history files and destroy
        visit show_path
        wait_for_js_ready
        within "#addon-cms-agents-addons-file" do
          expect(page).to have_css('.file-view', text: "replaced")
          wait_cbox_open do
            click_on I18n.t("ss.buttons.replace_file")
          end
        end

        wait_for_cbox do
          wait_for_js_ready
          click_on I18n.t("ss.buttons.file_histories")

          within "table.index tbody" do
            expect(all("tr").size).to eq 3
            within all("tr").last do
              expect(page).to have_css("td", text: "before_csv.csv")
              expect(page).to have_css("a", text: I18n.t('history.buttons.restore'))
              expect(page).to have_css("a", text: I18n.t("ss.links.download"))
              expect(page).to have_css("a", text: I18n.t("ss.buttons.delete"))

              wait_event_to_fire "ss:ajaxRemoved", "#addon-cms-agents-addons-file .replace-file .ajax-box" do
                page.accept_confirm do
                  click_on I18n.t("ss.buttons.delete")
                end
              end
            end
          end

          within "table.index tbody" do
            expect(all("tr").size).to eq 2
          end
        end
      end
    end
  end
end
