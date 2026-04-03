require 'spec_helper'

describe "gws_bookmark_folders", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:folder0) { user.bookmark_root_folder(site) }
  let!(:folder1) { create :gws_bookmark_folder, cur_site: site, cur_user: user, in_parent: folder0.id, in_basename: unique_id }
  let!(:folder2) { create :gws_bookmark_folder, cur_site: site, cur_user: user, in_parent: folder1.id, in_basename: unique_id }
  let!(:item1) { create :gws_bookmark_item, cur_site: site, cur_user: user, folder: folder2 }

  context "delete parent" do
    it do
      login_user user, to: gws_bookmark_folders_path(site: site)
      within "[data-id='#{folder1.id}']" do
        click_on folder1.name
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        # 下階層やブックマークが存在する場合、削除する前に警告があっても良さそうだけど、
        # 警告もなく削除される。ちょっと不親切。
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      # ブックマークフォルダーは下階層があっても削除できる、階層のフォルダーを全て削除する
      expect { folder0.reload }.not_to raise_error
      expect { folder1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { folder2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { item1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
