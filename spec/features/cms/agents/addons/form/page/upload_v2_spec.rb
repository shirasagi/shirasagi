require 'spec_helper'

describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: cms_user.group_ids) }
  let!(:column1) do
    create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", file_type: "video", order: 1)
  end
  let!(:node) { create :article_node_page, cur_site: site, st_form_ids: [ form.id ], st_form_default_id: form.id }
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

        within "#addon-cms-agents-addons-form-page .column-value-cms-column-fileupload" do
          within '.file-view' do
            expect(page).to have_css('.name', text: filename)
          end
        end
      end
    end

    context "edit" do
      it do
        within_dialog do
          within ".file-view[data-file-id='#{file.id}']" do
            expect(page).to have_css(".name", text: filename)
            click_on I18n.t("ss.buttons.edit")
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

      within "#addon-cms-agents-addons-form-page" do
        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column1.name
          end
        end

        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within ".column-value-cms-column-fileupload" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.buttons.select_from_list")
          end
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
              click_on I18n.t('ss.buttons.upload')
            end
          end
        end

        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within ".cms-tabs" do
              click_on I18n.t("ss.buttons.select_from_list")
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
    let(:file_type) { I18n.t("mongoid.models.ss/temp_file") }

    it_behaves_like "several operations on file dialog"
  end

  context "with ss/user_file" do
    let!(:file) do
      tmp_ss_file(
        SS::UserFile, model: "ss/user_file", user: cms_user, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:file_type) { I18n.t("mongoid.models.ss/user_file") }

    it_behaves_like "several operations on file dialog"
  end

  context "with cms/file" do
    let!(:file) do
      tmp_ss_file(
        Cms::File, model: "cms/file", user: cms_user, site: site, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:file_type) { I18n.t("mongoid.models.cms/file") }

    it_behaves_like "several operations on file dialog"
  end

  context "upload file dialog" do
    context "via file input" do
      context "usual case" do
        let(:name) { "name-#{unique_id}.png" }
        let(:filename) { "filename-#{unique_id}.png" }

        it do
          visit article_pages_path(site: site, cid: node)
          click_on I18n.t("ss.links.new")
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames

          within "#addon-cms-agents-addons-form-page" do
            within ".column-value-palette" do
              wait_for_event_fired("ss:columnAdded") do
                click_on column1.name
              end
            end
          end
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames
          within "#addon-cms-agents-addons-form-page" do
            within ".column-value-cms-column-fileupload" do
              wait_for_cbox_opened do
                click_on I18n.t('ss.links.upload')
              end
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
                  fill_in "item[files][][filename]", with: filename
                end

                click_on I18n.t("ss.buttons.upload")
              end
            end
          end
          within "#addon-cms-agents-addons-form-page" do
            within ".column-value-cms-column-fileupload" do
              expect(page).to have_css(".file-view", text: name)
            end
          end

          expect(Cms::TempFile.all.count).to eq 1
          Cms::TempFile.all.first.tap do |file|
            expect(file.site_id).to eq site.id
            expect(file.user_id).to eq cms_user.id
            expect(file.node_id).to eq node.id
            expect(file.model).to eq "ss/temp_file"
            expect(file.name).to eq name
            expect(file.filename).to eq filename
            expect(file.content_type).to eq "image/png"
            expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/logo.png")
          end
        end
      end
    end
  end
end
