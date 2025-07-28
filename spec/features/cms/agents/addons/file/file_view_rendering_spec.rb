require 'spec_helper'

# 既定フィールドの詳細画面テスト
describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site, cur_user: cms_user }
  let!(:file) { tmp_ss_file contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: cms_user, basename: "#{unique_id}.jpg" }
  let(:logo_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let(:keyvisual_path) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg" }

  before do
    login_cms_user
  end

  context "with article/page" do
    describe "index" do
      it do
        visit article_pages_path(site: site, cid: node)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        logo_file = nil
        keyvisual_file = nil
        within "form#item-form" do
          fill_in "item[name]", with: "sample"

          ss_upload_file logo_path, keyvisual_path
          within "#addon-cms-agents-addons-file" do
            expect(page).to have_css(".file-view", count: 2)

            logo_file = SS::File.find_by(name: File.basename(logo_path))
            keyvisual_file = SS::File.find_by(name: File.basename(keyvisual_path))
            expect(page).to have_css(".file-view[data-file-id='#{logo_file.id}']", text: logo_file.name)
            expect(page).to have_css(".file-view[data-file-id='#{keyvisual_file.id}']", text: keyvisual_file.name)
          end

          wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
            within "#addon-cms-agents-addons-file" do
              within ".file-view[data-file-id='#{keyvisual_file.id}']" do
                click_on I18n.t("sns.file_attach")
              end
            end
          end

          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within "#addon-cms-agents-addons-file" do
          element = find(".file-view[data-file-id='#{keyvisual_file.id}']")
          expect(element['class']).not_to include('unused')

          element = find(".file-view[data-file-id='#{logo_file.id}']")
          expect(element['class']).to include('unused')

          expect(page).to have_css(".file-view.unused", text: logo_file.name)
        end
      end

      it "should display deletion button for unused file and delete it successfully" do
        visit article_pages_path(site: site, cid: node)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t("ss.links.new")
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        logo_file = nil
        keyvisual_file = nil
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          click_on I18n.t("ss.links.input")
          fill_in "item[basename]", with: "sample"

          ss_upload_file logo_path, keyvisual_path
          within "#addon-cms-agents-addons-file" do
            expect(page).to have_css(".file-view", count: 2)

            logo_file = SS::File.find_by(name: File.basename(logo_path))
            keyvisual_file = SS::File.find_by(name: File.basename(keyvisual_path))

            expect(page).to have_css(".file-view[data-file-id='#{logo_file.id}']", text: logo_file.name)
            expect(page).to have_css(".file-view[data-file-id='#{keyvisual_file.id}']", text: keyvisual_file.name)
          end

          wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
            within "#addon-cms-agents-addons-file" do
              within ".file-view[data-file-id='#{keyvisual_file.id}']" do
                click_on I18n.t("sns.file_attach")
              end
            end
          end

          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within "#addon-cms-agents-addons-file" do
          within ".file-view.unused" do
            expect(page).to have_content(I18n.t("ss.unused_file"))
            expect(page).to have_content(I18n.t("ss.buttons.delete"))
            wait_for_cbox_opened { click_link I18n.t("ss.buttons.delete") }
          end
        end

        within_cbox do
          within 'form#ajax-form' do
            within "footer.send" do
              click_on I18n.t("ss.buttons.delete")
            end
          end
        end

        within "#addon-cms-agents-addons-file" do
          expect(page).to have_no_css(".file-view.unused")
        end
      end
    end
  end
end

# 自由入力の詳細画面テスト
describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node) do
    create :article_node_page, cur_site: site, cur_user: cms_user, filename: "docs", name: "article", group_ids: [cms_group.id],
    st_form_ids: [form.id]
  end
  let!(:item) { create :article_page, cur_node: node, group_ids: [cms_group.id] }
  let!(:edit_path) { edit_article_page_path site.id, node, item }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }
  let!(:column2) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 2) }
  let!(:file) { tmp_ss_file contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: cms_user, basename: "#{unique_id}.jpg" }
  let(:logo_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

  before do
    login_cms_user
    visit edit_path
    wait_for_all_ckeditors_ready
    wait_for_all_turbo_frames
  end

  it "allows file uploads in form" do
    within 'form#item-form' do
      wait_for_event_fired("ss:formActivated") do
        page.accept_confirm(I18n.t("cms.confirm.change_form")) do
          select form.name, from: 'in_form_id'
        end
      end
    end
    wait_for_all_ckeditors_ready
    wait_for_all_turbo_frames

    shirasagi_path = "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
    logo_path = "#{Rails.root}/spec/fixtures/ss/logo.png"

    shirasagi_file = nil
    logo_file = nil

    within 'form#item-form' do
      within ".column-value-palette" do
        wait_for_event_fired("ss:columnAdded") do
          click_on column2.name
        end
      end
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      ss_upload_file shirasagi_path, logo_path, addon: ".column-value-cms-column-free"
      within ".column-value-cms-column-free" do
        expect(page).to have_css(".file-view", count: 2)

        shirasagi_file = SS::File.find_by(name: File.basename(shirasagi_path))
        logo_file = SS::File.find_by(name: File.basename(logo_path))
        expect(page).to have_css(".file-view[data-file-id='#{shirasagi_file.id}']", text: shirasagi_file.name)
        expect(page).to have_css(".file-view[data-file-id='#{logo_file.id}']", text: logo_file.name)
      end

      within ".column-value-cms-column-free" do
        wait_for_ckeditor_event 'item[column_values][][in_wrap][value]', "afterInsertHtml" do
          within ".file-view[data-file-id='#{logo_file.id}']" do
            within ".action" do
              click_on I18n.t("sns.image_paste")
            end
          end
        end
      end

      click_on I18n.t("ss.buttons.publish_save")
    end

    click_on I18n.t("ss.buttons.ignore_alert")
    wait_for_notice I18n.t('ss.notice.saved')
    wait_for_all_ckeditors_ready
    wait_for_all_turbo_frames

    within '#addon-cms-agents-addons-form-page' do
      within ".column-value-cms-column-free" do
        expect(page).to have_css(".file-view", text: 'logo.png')
        element = find(".file-view[data-file-id='#{logo_file.id}']")
        expect(element['class']).not_to include('unused')
        element = find(".file-view[data-file-id='#{shirasagi_file.id}']")
        expect(element['class']).to include('unused')
        expect(page).to have_css(".file-view.unused", text: shirasagi_file.name)
        expect(page).to have_content(I18n.t("ss.unused_file"))

        within ".file-view.unused" do
          expect(page).to have_link(I18n.t("ss.buttons.delete"))
        end
      end
    end

    clear_notice

    within '#addon-cms-agents-addons-form-page' do
      within ".column-value-cms-column-free" do
        within ".file-view.unused" do
          expect(page).to have_link(I18n.t("ss.buttons.delete"))
          wait_for_cbox_opened { click_link I18n.t("ss.buttons.delete") }
        end
      end
    end

    within_cbox do
      within "footer.send" do
        click_on I18n.t("ss.buttons.delete")
      end
    end
    wait_for_notice I18n.t("ss.notice.deleted")

    within '#addon-cms-agents-addons-form-page' do
      within ".column-value-cms-column-free" do
        expect(page).to have_css(".file-view", text: 'logo.png')
        expect(page).to have_no_css(".file-view", text: 'shirasagi.pdf')
      end
    end
  end
end
