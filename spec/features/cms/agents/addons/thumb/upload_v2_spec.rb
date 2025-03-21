require 'spec_helper'

describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
  let(:filename) { "#{unique_id}.png" }

  before do
    @save_file_upload_dialog = SS.file_upload_dialog
    SS.file_upload_dialog = :v2

    login_cms_user
  end

  after do
    SS.file_upload_dialog = @save_file_upload_dialog
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

        within "#item-form #addon-cms-agents-addons-thumb" do
          expect(page).to have_css('.ss-file-field-v2 .humanized-name', text: file.humanized_name)
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

  shared_examples "several operations on file dialog" do
    before do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within "#item-form #addon-cms-agents-addons-thumb" do
        wait_for_cbox_opened do
          click_on I18n.t("ss.buttons.upload")
        end
      end

      wait_for_event_fired "turbo:frame-load" do
        within_dialog do
          within ".cms-tabs" do
            click_on I18n.t("ss.buttons.select_from_list")
          end
        end
      end

      el = page.find(:checkbox, menu_label)
      unless el["checked"]
        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within "form.search" do
              check menu_label
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
  end

  context "with cms/temp_file" do
    let!(:file) do
      tmp_ss_file(
        Cms::TempFile, user: cms_user, site: site, node: node, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:menu_label) { I18n.t("mongoid.models.ss/temp_file") }

    it_behaves_like "several operations on file dialog"
  end

  context "with ss/user_file" do
    let!(:file) do
      tmp_ss_file(
        SS::UserFile, model: "ss/user_file", user: cms_user, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:menu_label) { I18n.t("mongoid.models.ss/user_file") }

    it_behaves_like "several operations on file dialog"
  end

  context "with cms/file" do
    let!(:file) do
      tmp_ss_file(
        Cms::File, model: "cms/file", user: cms_user, site: site, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png", group_ids: cms_user.group_ids
      )
    end
    let(:menu_label) { I18n.t("mongoid.models.cms/file") }

    it_behaves_like "several operations on file dialog"
  end

  context "upload file dialog" do
    context "via file input" do
      context "usual case" do
        let(:name) { "name-#{unique_id}.png" }

        it do
          visit article_pages_path(site: site, cid: node)
          click_on I18n.t("ss.links.new")
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames

          within "#item-form #addon-cms-agents-addons-thumb" do
            wait_for_cbox_opened do
              click_on I18n.t('ss.links.upload')
            end
          end
          within_dialog do
            wait_event_to_fire "ss:tempFile:addedWaitingList" do
              attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/logo.png"
            end
          end
          wait_for_cbox_closed do
            within_dialog do
              within "form" do
                within first(".index tbody tr") do
                  fill_in "item[files][][name]", with: name
                end

                click_on I18n.t("ss.buttons.upload")
              end
            end
          end
          within "#item-form #addon-cms-agents-addons-thumb" do
            expect(page).to have_css('.ss-file-field-v2 .humanized-name', text: File.basename(name, ".*"))
          end

          expect(Cms::TempFile.all.count).to eq 1
          Cms::TempFile.all.first.tap do |file|
            expect(file.site_id).to eq site.id
            expect(file.user_id).to eq cms_user.id
            expect(file.node_id).to eq node.id
            expect(file.model).to eq "ss/temp_file"
            expect(file.name).to eq name
            expect(file.filename).to eq name
            expect(file.content_type).to eq "image/png"
            expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
          end
        end
      end

      context "without ext (case 1)" do
        let(:name) { "name-#{unique_id}" }

        it do
          visit article_pages_path(site: site, cid: node)
          click_on I18n.t("ss.links.new")
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames

          within "#item-form #addon-cms-agents-addons-thumb" do
            wait_for_cbox_opened do
              click_on I18n.t('ss.links.upload')
            end
          end
          within_dialog do
            wait_event_to_fire "ss:tempFile:addedWaitingList" do
              attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/logo.png"
            end
          end
          wait_for_cbox_closed do
            within_dialog do
              within "form" do
                within first(".index tbody tr") do
                  fill_in "item[files][][name]", with: name
                end

                click_on I18n.t("ss.buttons.upload")
              end
            end
          end
          within "#item-form #addon-cms-agents-addons-thumb" do
            expect(page).to have_css('.ss-file-field-v2 .humanized-name', text: name)
          end

          expect(Cms::TempFile.all.count).to eq 1
          Cms::TempFile.all.first.tap do |file|
            expect(file.site_id).to eq site.id
            expect(file.user_id).to eq cms_user.id
            expect(file.node_id).to eq node.id
            expect(file.model).to eq "ss/temp_file"
            expect(file.name).to eq "#{name}.png"
            expect(file.filename).to eq "#{name}.png"
            expect(file.content_type).to eq "image/png"
            expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
          end
        end
      end

      # ピリオドで終了するケース
      context "without ext (case 2)" do
        let(:name) { "name-#{unique_id}." }

        it do
          visit article_pages_path(site: site, cid: node)
          click_on I18n.t("ss.links.new")
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames

          within "#item-form #addon-cms-agents-addons-thumb" do
            wait_for_cbox_opened do
              click_on I18n.t('ss.links.upload')
            end
          end
          within_dialog do
            wait_event_to_fire "ss:tempFile:addedWaitingList" do
              attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/logo.png"
            end
          end
          wait_for_cbox_closed do
            within_dialog do
              within "form" do
                within first(".index tbody tr") do
                  fill_in "item[files][][name]", with: name
                end

                click_on I18n.t("ss.buttons.upload")
              end
            end
          end
          within "#item-form #addon-cms-agents-addons-thumb" do
            expect(page).to have_css('.ss-file-field-v2 .humanized-name', text: File.basename(name, ".*"))
          end

          expect(Cms::TempFile.all.count).to eq 1
          Cms::TempFile.all.first.tap do |file|
            expect(file.site_id).to eq site.id
            expect(file.user_id).to eq cms_user.id
            expect(file.node_id).to eq node.id
            expect(file.model).to eq "ss/temp_file"
            expect(file.name).to eq "#{name}png"
            expect(file.filename).to eq "#{name}png"
            expect(file.content_type).to eq "image/png"
            expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
          end
        end
      end

      context "with different ext" do
        let(:name) { "name-#{unique_id}.txt" }

        it do
          visit article_pages_path(site: site, cid: node)
          click_on I18n.t("ss.links.new")
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames

          within "#item-form #addon-cms-agents-addons-thumb" do
            wait_for_cbox_opened do
              click_on I18n.t('ss.links.upload')
            end
          end
          within_dialog do
            wait_event_to_fire "ss:tempFile:addedWaitingList" do
              attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/logo.png"
            end
          end
          wait_for_cbox_closed do
            within_dialog do
              within "form" do
                within first(".index tbody tr") do
                  fill_in "item[files][][name]", with: name
                end

                click_on I18n.t("ss.buttons.upload")
              end
            end
          end
          within "#item-form #addon-cms-agents-addons-thumb" do
            expect(page).to have_css('.ss-file-field-v2 .humanized-name', text: name)
          end

          expect(Cms::TempFile.all.count).to eq 1
          Cms::TempFile.all.first.tap do |file|
            expect(file.site_id).to eq site.id
            expect(file.user_id).to eq cms_user.id
            expect(file.node_id).to eq node.id
            expect(file.model).to eq "ss/temp_file"
            expect(file.name).to eq "#{name}.png"
            expect(file.filename).to eq "#{name}.png"
            expect(file.content_type).to eq "image/png"
            expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
          end
        end
      end

      context "with empty name" do
        let(:name) { "" }

        it do
          visit article_pages_path(site: site, cid: node)
          click_on I18n.t("ss.links.new")
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames

          within "#item-form #addon-cms-agents-addons-thumb" do
            wait_for_cbox_opened do
              click_on I18n.t('ss.links.upload')
            end
          end
          within_dialog do
            wait_event_to_fire "ss:tempFile:addedWaitingList" do
              attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/logo.png"
            end
          end
          within_dialog do
            within "form" do
              within first(".index tbody tr") do
                fill_in "item[files][][name]", with: name
              end

              click_on I18n.t("ss.buttons.upload")
            end
          end

          within_dialog do
            within "form" do
              within first(".index tbody tr") do
                message = I18n.t("errors.messages.blank")
                message = I18n.t("errors.format", attribute: SS::File.t(:name), message: message)
                expect(page).to have_css(".errors", text: message)
              end
            end
          end

          expect(SS::File.all.count).to eq 0
        end
      end

      context "with invalid name" do
        # 絵文字など Shift_JIS / CP932 の範囲外にある Unicode は禁止
        let(:name) { "😀.png" }

        it do
          visit article_pages_path(site: site, cid: node)
          click_on I18n.t("ss.links.new")
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames

          within "#item-form #addon-cms-agents-addons-thumb" do
            wait_for_cbox_opened do
              click_on I18n.t('ss.links.upload')
            end
          end
          within_dialog do
            wait_event_to_fire "ss:tempFile:addedWaitingList" do
              attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/logo.png"
            end
          end
          within_dialog do
            within "form" do
              within first(".index tbody tr") do
                fill_in "item[files][][name]", with: name
              end

              click_on I18n.t("ss.buttons.upload")
            end
          end

          within_dialog do
            within "form" do
              within first(".index tbody tr") do
                message = I18n.t("errors.messages.invalid")
                message = I18n.t("errors.format", attribute: SS::File.t(:name), message: message)
                expect(page).to have_css(".errors", text: message)
              end
            end
          end

          expect(SS::File.all.count).to eq 0
        end
      end

      context "with invalid name with multibyte_filename_state disabled (case 1)" do
        let(:name1) { "セーフ.png" }
        let(:name2) { "name-#{unique_id}.png" }

        before do
          site.update!(multibyte_filename_state: 'disabled')
        end

        it do
          visit article_pages_path(site: site, cid: node)
          click_on I18n.t("ss.links.new")
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames

          within "#item-form #addon-cms-agents-addons-thumb" do
            wait_for_cbox_opened do
              click_on I18n.t('ss.links.upload')
            end
          end
          within_dialog do
            wait_event_to_fire "ss:tempFile:addedWaitingList" do
              attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/logo.png"
            end
          end
          within_dialog do
            within "form" do
              within first(".index tbody tr") do
                fill_in "item[files][][name]", with: name1
              end

              click_on I18n.t("ss.buttons.upload")
            end
          end

          within_dialog do
            within "form" do
              within first(".index tbody tr") do
                message = I18n.t("errors.messages.invalid_filename")
                message = I18n.t("errors.format", attribute: SS::File.t(:name), message: message)
                expect(page).to have_css(".errors", text: message)
              end
            end
          end

          expect(SS::File.all.count).to eq 0

          wait_for_cbox_closed do
            within_dialog do
              within "form" do
                within first(".index tbody tr") do
                  fill_in "item[files][][name]", with: name2
                end

                click_on I18n.t("ss.buttons.upload")
              end
            end
          end
          within "#item-form #addon-cms-agents-addons-thumb" do
            expect(page).to have_css('.ss-file-field-v2 .humanized-name', text: File.basename(name2, ".*"))
          end

          expect(Cms::TempFile.all.count).to eq 1
          Cms::TempFile.all.first.tap do |file|
            expect(file.site_id).to eq site.id
            expect(file.user_id).to eq cms_user.id
            expect(file.node_id).to eq node.id
            expect(file.model).to eq "ss/temp_file"
            expect(file.name).to eq name2
            expect(file.filename).to eq name2
            expect(file.content_type).to eq "image/png"
            expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
          end
        end
      end

      context "with invalid name with multibyte_filename_state disabled (case 2)" do
        let(:name) { "name-#{unique_id}.png" }

        before do
          site.update!(multibyte_filename_state: 'disabled')
        end

        it do
          visit article_pages_path(site: site, cid: node)
          click_on I18n.t("ss.links.new")
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames

          within "#item-form #addon-cms-agents-addons-thumb" do
            wait_for_cbox_opened do
              click_on I18n.t('ss.links.upload')
            end
          end
          within_dialog do
            wait_event_to_fire "ss:tempFile:addedWaitingList" do
              attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/ロゴ.png"
            end
          end
          within_dialog do
            within "form" do
              click_on I18n.t("ss.buttons.upload")
            end
          end
          within_dialog do
            within "form" do
              within first(".index tbody tr") do
                message = I18n.t("errors.messages.invalid_filename")
                message = I18n.t("errors.format", attribute: SS::File.t(:name), message: message)
                expect(page).to have_css(".errors", text: message)
              end
            end
          end

          expect(SS::File.all.count).to eq 0

          wait_for_cbox_closed do
            within_dialog do
              within "form" do
                within first(".index tbody tr") do
                  fill_in "item[files][][name]", with: name
                end

                click_on I18n.t("ss.buttons.upload")
              end
            end
          end
          within "#item-form #addon-cms-agents-addons-thumb" do
            expect(page).to have_css('.ss-file-field-v2 .humanized-name', text: File.basename(name, ".*"))
          end

          expect(Cms::TempFile.all.count).to eq 1
          Cms::TempFile.all.first.tap do |file|
            expect(file.site_id).to eq site.id
            expect(file.user_id).to eq cms_user.id
            expect(file.node_id).to eq node.id
            expect(file.model).to eq "ss/temp_file"
            expect(file.name).to eq name
            expect(file.filename).to eq name
            expect(file.content_type).to eq "image/png"
            expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
          end
        end
      end

      context "with non image files" do
        it do
          visit article_pages_path(site: site, cid: node)
          click_on I18n.t("ss.links.new")
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames

          within "#item-form #addon-cms-agents-addons-thumb" do
            wait_for_cbox_opened do
              click_on I18n.t('ss.links.upload')
            end
          end
          within_dialog do
            wait_event_to_fire "ss:tempFile:addedWaitingList" do
              attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
            end
          end
          within_dialog do
            within "form" do
              click_on I18n.t("ss.buttons.upload")
            end
          end
          within_dialog do
            within "form" do
              within first(".index tbody tr") do
                list = SS::File::IMAGE_FILE_EXTENSIONS.join(" / ")
                message = I18n.t("errors.messages.unable_to_accept_file", allowed_format_list: list)
                message = I18n.t("errors.format", attribute: SS::File.t(:in_files), message: message)
                expect(page).to have_css(".errors", text: message)
              end
            end
          end

          expect(Cms::TempFile.all.count).to eq 0
        end
      end
    end

    context "drop file with valid name" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within "#item-form #addon-cms-agents-addons-thumb" do
          wait_for_cbox_opened do
            click_on I18n.t('ss.links.upload')
          end
        end
        within_dialog do
          wait_event_to_fire "ss:tempFile:addedWaitingList" do
            ss_drop_file ".search-ui-form", "#{Rails.root}/spec/fixtures/ss/logo.png"
          end
        end
        wait_for_cbox_closed do
          within_dialog do
            within "form" do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
        within "#item-form #addon-cms-agents-addons-thumb" do
          expect(page).to have_css('.ss-file-field-v2 .humanized-name', text: "logo")
        end

        expect(Cms::TempFile.all.count).to eq 1
        Cms::TempFile.all.first.tap do |file|
          expect(file.site_id).to eq site.id
          expect(file.user_id).to eq cms_user.id
          expect(file.node_id).to eq node.id
          expect(file.model).to eq "ss/temp_file"
          expect(file.name).to eq "logo.png"
          expect(file.filename).to eq "logo.png"
          expect(file.content_type).to eq "image/png"
          expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
        end
      end
    end

    context "drop file with invalid name with multibyte_filename_state disabled" do
      let(:name) { "name-#{unique_id}.png" }

      before do
        site.update!(multibyte_filename_state: 'disabled')
      end

      it do
        visit article_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within "#item-form #addon-cms-agents-addons-thumb" do
          wait_for_cbox_opened do
            click_on I18n.t('ss.links.upload')
          end
        end
        within_dialog do
          wait_event_to_fire "ss:tempFile:addedWaitingList" do
            ss_drop_file ".search-ui-form", "#{Rails.root}/spec/fixtures/ss/ロゴ.png"
          end
        end
        within_dialog do
          within "form" do
            within first(".index tbody tr") do
              message = I18n.t("errors.messages.invalid_filename")
              message = I18n.t("errors.format", attribute: SS::File.t(:name), message: message)
              expect(page).to have_css(".errors", text: message)
            end
          end
        end

        expect(SS::File.all.count).to eq 0

        wait_for_cbox_closed do
          within_dialog do
            within "form" do
              within first(".index tbody tr") do
                fill_in "item[files][][name]", with: name
              end

              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
        within "#item-form #addon-cms-agents-addons-thumb" do
          expect(page).to have_css('.ss-file-field-v2 .humanized-name', text: File.basename(name, ".*"))
        end

        expect(Cms::TempFile.all.count).to eq 1
        Cms::TempFile.all.first.tap do |file|
          expect(file.site_id).to eq site.id
          expect(file.user_id).to eq cms_user.id
          expect(file.node_id).to eq node.id
          expect(file.model).to eq "ss/temp_file"
          expect(file.name).to eq name
          expect(file.filename).to eq name
          expect(file.content_type).to eq "image/png"
          expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
        end
      end
    end

    context "drop non image file" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within "#item-form #addon-cms-agents-addons-thumb" do
          wait_for_cbox_opened do
            click_on I18n.t('ss.links.upload')
          end
        end
        within_dialog do
          wait_event_to_fire "ss:tempFile:addedWaitingList" do
            ss_drop_file ".search-ui-form", "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
          end
        end
        within_dialog do
          within "form" do
            click_on I18n.t("ss.buttons.upload")
          end
        end
        within_dialog do
          within "form" do
            within first(".index tbody tr") do
              list = SS::File::IMAGE_FILE_EXTENSIONS.join(" / ")
              message = I18n.t("errors.messages.unable_to_accept_file", allowed_format_list: list)
              message = I18n.t("errors.format", attribute: SS::File.t(:in_files), message: message)
              expect(page).to have_css(".errors", text: message)
            end
          end
        end

        expect(Cms::TempFile.all.count).to eq 0
      end
    end
  end

  context "directly drop file with valid name" do
    it do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within "#item-form #addon-cms-agents-addons-thumb" do
        wait_for_cbox_opened do
          ss_drop_file ".ss-file-field-v2", "#{Rails.root}/spec/fixtures/ss/logo.png"
        end
      end
      wait_for_cbox_closed do
        within_dialog do
          within "form" do
            click_on I18n.t("ss.buttons.upload")
          end
        end
      end
      within "#item-form #addon-cms-agents-addons-thumb" do
        expect(page).to have_css('.ss-file-field-v2 .humanized-name', text: "logo")
      end

      expect(Cms::TempFile.all.count).to eq 1
      Cms::TempFile.all.first.tap do |file|
        expect(file.site_id).to eq site.id
        expect(file.user_id).to eq cms_user.id
        expect(file.node_id).to eq node.id
        expect(file.model).to eq "ss/temp_file"
        expect(file.name).to eq "logo.png"
        expect(file.filename).to eq "logo.png"
        expect(file.content_type).to eq "image/png"
        expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
      end
    end
  end

  context "directly drop file with invalid name" do
    let(:name) { "name-#{unique_id}.png" }

    before do
      site.update!(multibyte_filename_state: 'disabled')
    end

    it do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within "#item-form #addon-cms-agents-addons-thumb" do
        wait_for_cbox_opened do
          ss_drop_file ".ss-file-field-v2", "#{Rails.root}/spec/fixtures/ss/ロゴ.png"
        end
      end
      within_dialog do
        within "form" do
          within first(".index tbody tr") do
            message = I18n.t("errors.messages.invalid_filename")
            message = I18n.t("errors.format", attribute: SS::File.t(:name), message: message)
            expect(page).to have_css(".errors", text: message)
          end
        end
      end

      expect(SS::File.all.count).to eq 0

      wait_for_cbox_closed do
        within_dialog do
          within "form" do
            within first(".index tbody tr") do
              fill_in "item[files][][name]", with: name
            end

            click_on I18n.t("ss.buttons.upload")
          end
        end
      end
      within "#item-form #addon-cms-agents-addons-thumb" do
        expect(page).to have_css('.ss-file-field-v2 .humanized-name', text: File.basename(name, ".*"))
      end

      expect(Cms::TempFile.all.count).to eq 1
      Cms::TempFile.all.first.tap do |file|
        expect(file.site_id).to eq site.id
        expect(file.user_id).to eq cms_user.id
        expect(file.node_id).to eq node.id
        expect(file.model).to eq "ss/temp_file"
        expect(file.name).to eq name
        expect(file.filename).to eq name
        expect(file.content_type).to eq "image/png"
        expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
      end
    end
  end

  context "directly drop file with non image file" do
    let(:name) { "name-#{unique_id}.png" }

    before do
      site.update!(multibyte_filename_state: 'disabled')
    end

    it do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within "#item-form #addon-cms-agents-addons-thumb" do
        wait_for_cbox_opened do
          ss_drop_file ".ss-file-field-v2", "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
        end
      end
      within_dialog do
        within "form" do
          click_on I18n.t("ss.buttons.upload")
        end
      end
      within_dialog do
        within "form" do
          within first(".index tbody tr") do
            list = SS::File::IMAGE_FILE_EXTENSIONS.join(" / ")
            message = I18n.t("errors.messages.unable_to_accept_file", allowed_format_list: list)
            message = I18n.t("errors.format", attribute: SS::File.t(:in_files), message: message)
            expect(page).to have_css(".errors", text: message)
          end
        end
      end

      expect(SS::File.all.count).to eq 0
    end
  end
end
