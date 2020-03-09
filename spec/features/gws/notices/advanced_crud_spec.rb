require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  #
  # 本 RSpec では次の 3 人が登場する。
  #
  # 管理者(manager): フォルダーを管理できる人。フォルダーの容量制限の設定が可能。
  # 作成者(editor): お知らせを作成できる人。フォルダーの管理はできない。
  # 閲覧者(reader): お知らせを閲覧できる人。お知らせは作成できないし、フォルダーの管理もできない。単に閲覧できる人。
  #
  # この 3 人を切り替えながら、お知らせ機能の仕様を確認する
  #
  # In this rspec, there are 3 users:
  #
  # manager: who can create / edit / read folders. who can also edit resource limitation settings.
  # editor: who can create / edit / read posts. who cannot create / edit folders.
  # reader: who can only read posts. who cannot create / edit posts and who cannot create / edit folders.
  #
  # By switching these 3 users, we'll confirm gws/notice specs.
  #
  let(:site) { gws_site }
  let!(:cate) { create :gws_notice_category, cur_site: site }
  let(:manager_group) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
  let(:editor_group) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
  let(:reader_group) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
  let(:manager_role) { create(:gws_role_notice_admin, :gws_role_portal_user_use) }
  let(:editor_role) { create(:gws_role_notice_editor, :gws_role_portal_user_use) }
  let(:reader_role) { create(:gws_role_notice_reader, :gws_role_portal_user_use) }
  let!(:manager) { create(:gws_user, group_ids: [ manager_group.id ], gws_role_ids: [ manager_role.id ]) }
  let!(:editor) { create(:gws_user, group_ids: [ editor_group.id ], gws_role_ids: [ editor_role.id ]) }
  let!(:reader) { create(:gws_user, group_ids: [ reader_group.id ], gws_role_ids: [ reader_role.id ]) }
  let(:folder_name) { unique_id }
  let(:notice_name) { unique_id }
  let(:notice_text) { unique_id }

  context do
    it do
      #
      # [manager] create folders
      #
      login_user manager
      visit gws_notice_folders_path(site: site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        fill_in 'item[in_basename]', with: folder_name

        within '.gws-addon-member' do
          click_on I18n.t('ss.apis.users.index')
        end
      end
      wait_for_cbox do
        expect(page).to have_content(site.name)
        find('button.dropdown.btn').click
        within '.dropdown-container' do
          click_on site.name
        end
        expect(page).to have_content(editor.name)
        click_on editor.name
      end
      within 'form#item-form' do
        within '.gws-addon-readable-setting' do
          click_on I18n.t('ss.buttons.delete')
          click_on I18n.t('ss.apis.users.index')
        end
      end
      wait_for_cbox do
        expect(page).to have_content(site.name)
        find('button.dropdown.btn').click
        within '.dropdown-container' do
          click_on site.name
        end
        expect(page).to have_content(reader.name)
        click_on reader.name
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Notice::Folder.all.count).to eq 1
      folder = Gws::Notice::Folder.all.first
      expect(folder.name).to eq folder_name
      expect(folder.member_ids).to eq [editor.id]
      expect(folder.member_group_ids).to eq []
      expect(folder.readable_member_ids).to eq [reader.id]
      expect(folder.readable_group_ids).to eq []
      expect(folder.user_ids).to eq [manager.id]
      expect(folder.group_ids).to eq [manager_group.id]

      #
      # [editor] create posts
      #
      login_user editor
      visit gws_notice_main_path(site: site)
      click_on I18n.t('ss.navi.editable')
      within '.tree-navi' do
        click_on folder_name
      end
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        fill_in 'item[name]', with: notice_name
        fill_in 'item[text]', with: notice_text
        click_on I18n.t("gws.apis.categories.index")
      end
      wait_for_cbox do
        expect(page).to have_content(cate.name)
        click_on cate.name
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Notice::Post.all.count).to eq 1
      Gws::Notice::Post.all.first.tap do |post|
        expect(post.name).to eq notice_name
        expect(post.text).to eq notice_text
        expect(post.folder_id).to eq folder.id
        expect(post.readable_member_ids).to eq folder.readable_member_ids
        expect(post.readable_group_ids).to eq folder.readable_group_ids
        expect(post.user_ids).to eq [editor.id]
        expect(post.group_ids).to eq [editor_group.id]
        expect(post.category_ids).to eq [cate.id]
      end

      #
      # [reader] read posts
      #
      login_user reader
      visit gws_notice_main_path(site: site)
      expect(page).to have_css('.tree-navi', text: folder_name)
      expect(page).to have_css('.list-items', text: notice_name)

      within '.tree-navi' do
        click_on folder_name
      end
      expect(page).to have_css('.tree-navi', text: folder_name)
      expect(page).to have_css('.list-items', text: notice_name)

      visit gws_portal_path(site: site)
      expect(page).to have_css('.list-items', text: notice_name)
    end
  end
end
