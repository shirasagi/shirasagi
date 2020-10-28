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
        within "form#item-form" do
          within "#addon-cms-agents-addons-file" do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        wait_for_cbox do
          attach_file "item[in_files][]", before_csv
          click_button I18n.t("ss.buttons.attach")
          wait_for_ajax
        end
        click_on I18n.t("ss.buttons.publish_save")
        wait_for_notice I18n.t('ss.notice.saved')

        5.times.each do
          # open replace file dialog
          within "#addon-cms-agents-addons-file" do
            click_on I18n.t("ss.buttons.replace_file")
          end

          # upload file and confirmation
          within "form#ajax-form" do
            attach_file "item[in_file]", after_csv
            click_button "確認画面へ"
            wait_for_ajax
          end

          # replace file
          within "form#ajax-form" do
            fill_in "item[name]", with: "replaced"
            click_button "差し替え保存"
          end
          wait_for_notice "差し替え保存しました。"
        end

        replaced_page = item.class.find(item.id)
        replaced_file = replaced_page.attached_files.first

        # history files
        expect(replaced_file.history_files.size).to eq 5
        history_file = replaced_file.history_files.last

        expect(history_file.filename).to eq "before_csv.csv"
        expect(history_file.name).to eq "before_csv.csv"
        expect(history_file.state).to eq "closed"
        expect(::FileUtils.cmp(history_file.path, before_csv)).to be true

        # show history files and restore
        visit show_path
        within "#addon-cms-agents-addons-file" do
          click_on I18n.t("ss.buttons.replace_file")
        end

        wait_for_cbox do
          click_on I18n.t("ss.buttons.file_histories")
          wait_for_ajax
        end

        within "#ajax-box table.index tbody" do
          expect(all("tr").size).to eq 5
          within all("tr").last do
            expect(page).to have_css("td", text: "before_csv.csv")
            expect(page).to have_css("a", text: "復元")
            expect(page).to have_css("a", text: I18n.t("ss.links.download"))
            expect(page).to have_css("a", text: I18n.t("ss.buttons.delete"))

            page.accept_confirm do
              click_on "復元"
            end
          end
        end

        wait_for_notice "復元しました。"

        replaced_page = item.class.find(item.id)
        replaced_file = replaced_page.attached_files.first
        expect(replaced_file.history_files.size).to eq 6

        expect(replaced_file.filename).to eq "before_csv.csv"
        expect(replaced_file.name).to eq "before_csv.csv"
        expect(replaced_file.state).to eq "public"
        expect(::FileUtils.cmp(replaced_file.path, before_csv)).to be true
      end

      it "destroy" do
        visit edit_path

        # original file upload
        within "form#item-form" do
          within "#addon-cms-agents-addons-file" do
            click_on I18n.t("ss.buttons.upload")
          end
        end

        wait_for_cbox do
          attach_file "item[in_files][]", before_csv
          click_button I18n.t("ss.buttons.attach")
          wait_for_ajax
        end
        click_on I18n.t("ss.buttons.publish_save")
        wait_for_notice I18n.t('ss.notice.saved')

        3.times.each do
          # open replace file dialog
          within "#addon-cms-agents-addons-file" do
            click_on I18n.t("ss.buttons.replace_file")
          end

          # upload file and confirmation
          within "form#ajax-form" do
            attach_file "item[in_file]", after_csv
            click_button "確認画面へ"
            wait_for_ajax
          end

          # replace file
          within "form#ajax-form" do
            fill_in "item[name]", with: "replaced"
            click_button "差し替え保存"
          end
          wait_for_notice "差し替え保存しました。"
        end

        replaced_page = item.class.find(item.id)
        replaced_file = replaced_page.attached_files.first

        # history files
        expect(replaced_file.history_files.size).to eq 3

        # show history files and destroy
        visit show_path
        within "#addon-cms-agents-addons-file" do
          click_on I18n.t("ss.buttons.replace_file")
        end

        wait_for_cbox do
          click_on I18n.t("ss.buttons.file_histories")
          wait_for_ajax
        end

        within "#ajax-box table.index tbody" do
          expect(all("tr").size).to eq 3
          within all("tr").last do
            expect(page).to have_css("td", text: "before_csv.csv")
            expect(page).to have_css("a", text: "復元")
            expect(page).to have_css("a", text: I18n.t("ss.links.download"))
            expect(page).to have_css("a", text: I18n.t("ss.buttons.delete"))

            page.accept_confirm do
              click_on I18n.t("ss.buttons.delete")
            end
          end
        end

        wait_for_ajax

        within "#ajax-box table.index tbody" do
          expect(all("tr").size).to eq 2
        end
      end
    end
  end
end
