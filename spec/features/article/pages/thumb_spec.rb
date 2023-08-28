require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) do
    create :article_node_page, filename: "docs", name: "article"
  end
  let(:item) { create :article_page, cur_node: node }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  context "attach thumb from upload" do
    before { login_cms_user }

    it "#edit" do
      visit edit_path

      ensure_addon_opened "#addon-cms-agents-addons-thumb"
      within "#addon-cms-agents-addons-thumb" do
        wait_event_to_fire("ss:dropdownOpened") { find('.dropdown-toggle').click }
        within ".dropdown-menu" do
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        wait_cbox_close do
          click_button I18n.t("ss.buttons.attach")
        end
      end

      within "#addon-cms-agents-addons-thumb" do
        expect(page).to have_css('span.humanized-name', text: 'keyvisual')
        expect(page).to have_no_css('span.humanized-name', text: 'JPG')
        expect(page).to have_css('span.humanized-name', text: 'GIF')
      end
    end

    it "#edit file name" do
      visit edit_path

      ensure_addon_opened "#addon-cms-agents-addons-thumb"
      within "#addon-cms-agents-addons-thumb" do
        wait_event_to_fire("ss:dropdownOpened") { find('.dropdown-toggle').click }
        within ".dropdown-menu" do
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

        click_on I18n.t("ss.buttons.edit")
        fill_in "item[name]", with: "modify.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css(".file-view", text: "modify.jpg")

        wait_cbox_close do
          click_on "modify.jpg"
        end
      end

      within "#addon-cms-agents-addons-thumb" do
        expect(page).to have_css('span.humanized-name', text: 'modify')
        expect(page).to have_css('span.humanized-name', text: 'JPG')
      end
    end
  end

  context "attach thumb from user file" do
    before { login_cms_user }

    it do
      visit edit_path

      ensure_addon_opened "#addon-cms-agents-addons-thumb"
      within "#addon-cms-agents-addons-thumb" do
        wait_event_to_fire("ss:dropdownOpened") { find('.dropdown-toggle').click }
        within ".dropdown-menu" do
          wait_cbox_open do
            click_on I18n.t("sns.user_file")
          end
        end
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        wait_cbox_close do
          click_button I18n.t("ss.buttons.attach")
        end
      end

      within "form#item-form" do
        within "#addon-cms-agents-addons-thumb" do
          expect(page).to have_css('span.humanized-name', text: 'keyvisual')
          expect(page).to have_no_css('span.humanized-name', text: 'JPG')
          expect(page).to have_css('span.humanized-name', text: 'GIF')
        end
        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.thumb.owner_item_type).to eq item.class.name
      expect(item.thumb.owner_item_id).to eq item.id
      expect(item.thumb.user_id).to eq cms_user.id
    end
  end

  context "attach thumb from cms file" do
    before { login_cms_user }

    it do
      visit edit_path

      ensure_addon_opened "#addon-cms-agents-addons-thumb"
      within "#addon-cms-agents-addons-thumb" do
        wait_event_to_fire("ss:dropdownOpened") { find('.dropdown-toggle').click }
        within ".dropdown-menu" do
          wait_cbox_open do
            click_on I18n.t("cms.file")
          end
        end
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        wait_cbox_close do
          click_button I18n.t("ss.buttons.attach")
        end
      end

      within "form#item-form" do
        within "#addon-cms-agents-addons-thumb" do
          expect(page).to have_css('span.humanized-name', text: 'keyvisual')
          expect(page).to have_no_css('span.humanized-name', text: 'JPG')
          expect(page).to have_css('span.humanized-name', text: 'GIF')
        end

        click_on I18n.t("ss.buttons.publish_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item.reload
      expect(item.thumb.owner_item_type).to eq item.class.name
      expect(item.thumb.owner_item_id).to eq item.id
      expect(item.thumb.user_id).to eq cms_user.id
    end

    context 'with rm_thumb' do
      it do
        visit edit_path

        ensure_addon_opened "#addon-cms-agents-addons-thumb"
        within "#addon-cms-agents-addons-thumb" do
          wait_event_to_fire("ss:dropdownOpened") { find('.dropdown-toggle').click }
          within ".dropdown-menu" do
            wait_cbox_open do
              click_on I18n.t("cms.file")
            end
          end
        end

        wait_for_cbox do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          click_button I18n.t("ss.buttons.save")
          expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within "form#item-form" do
          within "#addon-cms-agents-addons-thumb" do
            expect(page).to have_css('span.humanized-name', text: 'keyvisual')
            expect(page).to have_no_css('span.humanized-name', text: 'JPG')
            expect(page).to have_css('span.humanized-name', text: 'GIF')
          end

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        item.reload
        expect(item.thumb.owner_item_type).to eq item.class.name
        expect(item.thumb.owner_item_id).to eq item.id
        expect(item.thumb.user_id).to eq cms_user.id
        expect(SS::File.where(owner_item_type: 'Article::Page', owner_item_id: item.id).present?).to be_truthy

        visit edit_path

        ensure_addon_opened "#addon-cms-agents-addons-thumb"
        within "#addon-cms-agents-addons-thumb" do
          find('.btn-file-delete').click
        end

        within "form#item-form" do
          within "#addon-cms-agents-addons-thumb" do
            expect(page).to have_no_css('span.humanized-name', text: 'keyvisual')
          end

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        item.reload
        expect(item.thumb).to be_nil

        expect(SS::File.where(owner_item_type: 'Article::Page', owner_item_id: item.id).present?).to be_falsey
      end
    end

    context 'with cms addon file' do
      it do
        visit edit_path

        ensure_addon_opened "#addon-cms-agents-addons-thumb"
        within "#addon-cms-agents-addons-thumb" do
          wait_event_to_fire("ss:dropdownOpened") { find('.dropdown-toggle').click }
          within ".dropdown-menu" do
            wait_cbox_open do
              click_on I18n.t("cms.file")
            end
          end
        end

        wait_for_cbox do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within "#addon-cms-agents-addons-file" do
          wait_cbox_open do
            click_on I18n.t("cms.file")
          end
        end

        wait_for_cbox do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
          wait_cbox_close do
            click_button I18n.t("ss.buttons.attach")
          end
        end

        within "form#item-form" do
          within "#addon-cms-agents-addons-thumb" do
            expect(page).to have_css('span.humanized-name', text: 'keyvisual')
            expect(page).to have_css('span.humanized-name', text: 'JPG')
            expect(page).to have_no_css('span.humanized-name', text: 'GIF')
          end

          within '#selected-files' do
            expect(page).to have_no_css('.name', text: 'keyvisual.jpg')
            expect(page).to have_css('.name', text: 'keyvisual.gif')
          end

          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')

        item.reload
        expect(item.thumb.owner_item_type).to eq item.class.name
        expect(item.thumb.owner_item_id).to eq item.id
        expect(item.thumb.user_id).to eq cms_user.id

        expect(item.file_ids.length).to eq 1
        attached_file = item.files.first
        expect(attached_file.owner_item_type).to eq item.class.name
        expect(attached_file.owner_item_id).to eq item.id
        expect(attached_file.user_id).to eq cms_user.id
      end
    end
  end

  context "marge branch page with thumb" do
    let(:workflow_comment) { unique_id }
    let(:approve_comment1) { unique_id }

    before { login_cms_user }

    it do
      visit article_page_path(site: site, cid: node, id: item)
      expect do
        within "#addon-workflow-agents-addons-branch" do
          click_button I18n.t('workflow.create_branch')
        end
        within "#addon-workflow-agents-addons-branch" do
          expect(page).to have_content(item.name)
        end
      end.to output.to_stdout
      within "#addon-workflow-agents-addons-branch" do
        click_on item.name
      end

      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        ensure_addon_opened "#addon-cms-agents-addons-thumb"
        within "#addon-cms-agents-addons-thumb" do
          wait_event_to_fire("ss:dropdownOpened") { find('.dropdown-toggle').click }
          within ".dropdown-menu" do
            wait_cbox_open do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        wait_cbox_close do
          click_button I18n.t("ss.buttons.attach")
        end
      end
      expect do
        within "form#item-form" do
          within "#addon-cms-agents-addons-thumb" do
            expect(page).to have_css('span.humanized-name', text: 'keyvisual')
          end
          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end.to output.to_stdout

      item.reload
      expect(item.thumb).to be_present
      expect(item.thumb.name).to eq "keyvisual.jpg"
      expect(item.thumb.filename).to eq "keyvisual.jpg"
      expect(item.thumb.owner_item).to eq item
    end
  end
end
