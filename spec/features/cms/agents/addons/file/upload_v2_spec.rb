require 'spec_helper'

describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
  let(:filename) { "#{unique_id}.png" }

  before do
    login_cms_user
  end

  shared_examples "file dialog is" do
    context "click" do
      it do
        within_dialog do
          expect(page).to have_css('.file-view', text: filename)
          wait_for_cbox_closed do
            click_on filename
          end
        end

        within "#item-form #addon-cms-agents-addons-file" do
          within '#selected-files' do
            expect(page).to have_css('.name', text: filename)
          end
        end
      end
    end

    context "edit" do
      it do
        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within ".file-view[data-file-id='#{file.id}']" do
              expect(page).to have_css(".name", text: filename)
              click_on I18n.t("ss.buttons.edit")
            end
          end
        end

        within_dialog do
          expect(page).to have_css(".ss-image-edit-canvas")
        end
      end
    end

    context "delete" do
      it do
        within_dialog do
          within ".file-view[data-file-id='#{file.id}']" do
            expect(page).to have_css(".name", text: filename)
            wait_for_event_fired "ss:ajaxRemoved" do
              page.accept_confirm do
                click_on I18n.t("ss.buttons.delete")
              end
            end
          end
        end

        expect { file.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      end
    end
  end

  shared_examples "select a file from file dialog" do
    before do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within "#item-form #addon-cms-agents-addons-file" do
        wait_for_cbox_opened do
          click_on "一覧から選択"
        end
      end

      el = page.find(:checkbox, file_type)
      unless el["checked"]
        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within "form.search" do
              check file_type
            end
          end
        end
      end
    end

    context "default" do
      it_behaves_like "file dialog is"
    end

    context "after edit dialog is canceled" do
      before do
        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within ".file-view[data-file-id='#{file.id}']" do
              expect(page).to have_css(".name", text: filename)
              click_on I18n.t("ss.buttons.edit")
            end
          end
        end

        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            expect(page).to have_css(".ss-image-edit-canvas")
            within "form" do
              click_on I18n.t("ss.buttons.cancel")
            end
          end
        end
      end

      it_behaves_like "file dialog is"
    end

    context "after edit dialog is saved" do
      before do
        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within ".file-view[data-file-id='#{file.id}']" do
              expect(page).to have_css(".name", text: filename)
              click_on I18n.t("ss.buttons.edit")
            end
          end
        end

        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            expect(page).to have_css(".ss-image-edit-canvas")
            within "form" do
              click_on I18n.t("ss.buttons.save")
            end
          end
        end
      end

      it_behaves_like "file dialog is"
    end

    context "switch to upload adn back to list" do
      before do
        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within ".cms-tabs" do
              click_on I18n.t('ss.links.upload')
            end
          end
        end

        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within ".cms-tabs" do
              click_on "一覧"
            end
          end
        end
      end

      it_behaves_like "file dialog is"
    end
  end

  context "with cms/temp_file(ss/temp_file)" do
    let!(:file) do
      tmp_ss_file(
        Cms::TempFile, user: cms_user, site: site, node: node, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:file_type) { "一時ファイル" }

    it_behaves_like "select a file from file dialog"
  end

  context "with ss/user_file" do
    let!(:file) do
      tmp_ss_file(
        SS::UserFile, model: "ss/user_file", user: cms_user, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:file_type) { I18n.t("sns.user_file") }

    it_behaves_like "select a file from file dialog"
  end

  context "with cms/file" do
    let!(:file) do
      tmp_ss_file(
        Cms::File, model: "cms/file", user: cms_user, site: site, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:file_type) { I18n.t("cms.file") }

    it_behaves_like "select a file from file dialog"
  end

  context "upload file dialog" do
    context "via file input" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within "#item-form #addon-cms-agents-addons-file" do
          wait_for_cbox_opened do
            click_on I18n.t('ss.links.upload')
          end
        end
        within_dialog do
          attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/logo.png"
        end
        wait_for_cbox_closed do
          within_dialog do
            within "form" do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
        within "#item-form #addon-cms-agents-addons-file" do
          expect(page).to have_css(".file-view", text: "logo.png")
        end
      end
    end

    context "via drop" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within "#item-form #addon-cms-agents-addons-file" do
          wait_for_cbox_opened do
            click_on I18n.t('ss.links.upload')
          end
        end
        within_dialog do
          ss_drop_file ".search-ui-form", "#{Rails.root}/spec/fixtures/ss/logo.png"
        end
        wait_for_cbox_closed do
          within_dialog do
            within "form" do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
        within "#item-form #addon-cms-agents-addons-file" do
          expect(page).to have_css(".file-view", text: "logo.png")
        end
      end
    end
  end

  context "directly drop file" do
    it do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within "#item-form #addon-cms-agents-addons-file" do
        wait_for_cbox_opened do
          ss_drop_file ".cms-file-upload-drop-area", "#{Rails.root}/spec/fixtures/ss/logo.png"
        end
      end
      wait_for_cbox_closed do
        within_dialog do
          within "form" do
            click_on I18n.t("ss.buttons.upload")
          end
        end
      end
      within "#item-form #addon-cms-agents-addons-file" do
        expect(page).to have_css(".file-view", text: "logo.png")
      end
    end
  end

  context "reorder" do
    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:file1) do
      Timecop.freeze(now - 5.minutes) do
        tmp_ss_file(
          Cms::TempFile, user: cms_user, site: site, node: node, basename: "logo-1.png",
          contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
        )
      end
    end
    let!(:file2) do
      Timecop.freeze(now - 4.minutes) do
        tmp_ss_file(
          Cms::TempFile, user: cms_user, site: site, node: node, basename: "logo-2.png",
          contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
        )
      end
    end
    let!(:file3) do
      Timecop.freeze(now - 3.minutes) do
        tmp_ss_file(
          Cms::TempFile, user: cms_user, site: site, node: node, basename: "logo-3.png",
          contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
        )
      end
    end
    let!(:item) do
      create :article_page, cur_site: site, cur_user: cms_user, cur_node: node, file_ids: [ file1.id, file2.id, file3.id ]
    end

    it do
      visit article_pages_path(site: site, cid: node)

      click_on item.name
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      click_on I18n.t("ss.links.edit")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      # 初期状態は「アップロード順」
      within "#item-form #addon-cms-agents-addons-file" do
        expect(page).to have_css(".file-view", count: 3)
        file_views = all(".file-view")
        expect(file_views[0]).to have_css(".name", text: file3.name)
        expect(file_views[1]).to have_css(".name", text: file2.name)
        expect(file_views[2]).to have_css(".name", text: file1.name)
      end

      # 名前順
      within "#item-form #addon-cms-agents-addons-file" do
        wait_for_event_fired "change" do
          click_on I18n.t('ss.buttons.file_name_order')
        end
      end
      within "#item-form #addon-cms-agents-addons-file" do
        expect(page).to have_css(".file-view", count: 3)
        file_views = all(".file-view")
        expect(file_views[0]).to have_css(".name", text: file1.name)
        expect(file_views[1]).to have_css(".name", text: file2.name)
        expect(file_views[2]).to have_css(".name", text: file3.name)
      end

      # アップロード順
      within "#item-form #addon-cms-agents-addons-file" do
        wait_for_event_fired "change" do
          click_on I18n.t('ss.buttons.file_upload_order')
        end
      end
      within "#item-form #addon-cms-agents-addons-file" do
        expect(page).to have_css(".file-view", count: 3)
        file_views = all(".file-view")
        expect(file_views[0]).to have_css(".name", text: file3.name)
        expect(file_views[1]).to have_css(".name", text: file2.name)
        expect(file_views[2]).to have_css(".name", text: file1.name)
      end
    end
  end
end
