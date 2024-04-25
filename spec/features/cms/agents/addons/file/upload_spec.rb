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
        within "#ajax-box" do
          expect(page).to have_css('.file-view', text: filename)
          wait_for_cbox_closed do
            wait_event_to_fire "ss:ajaxFileSelected", "#addon-cms-agents-addons-file .ajax-box" do
              click_on filename
            end
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
        within "#ajax-box" do
          within ".file-view[data-file-id='#{file.id}']" do
            expect(page).to have_css(".name", text: filename)
            click_on I18n.t("ss.buttons.edit")
          end
        end

        within "#ajax-box" do
          expect(page).to have_css(".ss-image-edit-canvas")
        end
      end
    end

    context "delete" do
      it do
        within "#ajax-box" do
          within ".file-view[data-file-id='#{file.id}']" do
            expect(page).to have_css(".name", text: filename)
            wait_event_to_fire "ss:ajaxRemoved", "#addon-cms-agents-addons-file .ajax-box" do
              page.accept_confirm do
                click_on I18n.t("ss.buttons.delete")
              end
            end
          end
        end

        expect { file.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      end
    end

    context "save and click" do
      it do
        within "#ajax-box" do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          click_button I18n.t("ss.buttons.save")
          expect(page).to have_css('.file-view', text: 'keyvisual.jpg')
          wait_for_cbox_closed do
            wait_event_to_fire "ss:ajaxFileSelected", "#addon-cms-agents-addons-file .ajax-box" do
              click_on 'keyvisual.jpg'
            end
          end
        end

        within "#item-form #addon-cms-agents-addons-file" do
          within '#selected-files' do
            expect(page).to have_css('.name', text: 'keyvisual.jpg')
          end
        end
      end
    end

    context "attach" do
      it do
        within "#ajax-box" do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          wait_for_cbox_closed do
            wait_event_to_fire "ss:ajaxFileSelected", "#addon-cms-agents-addons-file .ajax-box" do
              click_button I18n.t("ss.buttons.attach")
            end
          end
        end

        within "#item-form #addon-cms-agents-addons-file" do
          within '#selected-files' do
            expect(page).to have_css('.name', text: 'keyvisual.jpg')
          end
        end
      end
    end
  end

  shared_examples "several operations on file dialog" do
    before do
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")

      within "#item-form #addon-cms-agents-addons-file" do
        wait_for_cbox_opened do
          click_on button_label
        end
      end

      within "#ajax-box" do
        page.execute_script("SS_AjaxFile.firesEvents = true;")
      end
    end

    context "default" do
      it_behaves_like "file dialog is"
    end

    context "after file is saved" do
      before do
        within "#ajax-box" do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          click_button I18n.t("ss.buttons.save")
          expect(page).to have_css('.file-view', text: 'logo.png')
        end
      end

      it_behaves_like "file dialog is"
    end

    context "after edit dialog is canceled" do
      before do
        within "#ajax-box" do
          within ".file-view[data-file-id='#{file.id}']" do
            expect(page).to have_css(".name", text: filename)
            click_on I18n.t("ss.buttons.edit")
          end
        end

        within "#ajax-box" do
          expect(page).to have_css(".ss-image-edit-canvas")
          within "#ajax-form" do
            click_on I18n.t("ss.buttons.cancel")
          end
        end
      end

      it_behaves_like "file dialog is"
    end

    context "after edit dialog is saved" do
      before do
        within "#ajax-box" do
          within ".file-view[data-file-id='#{file.id}']" do
            expect(page).to have_css(".name", text: filename)
            click_on I18n.t("ss.buttons.edit")
          end
        end

        within "#ajax-box" do
          expect(page).to have_css(".ss-image-edit-canvas")
          within "#ajax-form" do
            click_on I18n.t("ss.buttons.save")
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
    let(:button_label) { I18n.t("ss.buttons.upload") }

    it_behaves_like "several operations on file dialog"
  end

  context "with ss/user_file" do
    let!(:file) do
      tmp_ss_file(
        SS::UserFile, model: "ss/user_file", user: cms_user, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:button_label) { I18n.t("sns.user_file") }

    it_behaves_like "several operations on file dialog"
  end

  context "with cms/file" do
    let!(:file) do
      tmp_ss_file(
        Cms::File, model: "cms/file", user: cms_user, site: site, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:button_label) { I18n.t("cms.file") }

    it_behaves_like "several operations on file dialog"
  end
end
