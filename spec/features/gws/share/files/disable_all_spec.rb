require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let!(:item) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id], memo: "test" }
  let(:index_path) { gws_share_folder_files_path site, folder }

  describe "disable(soft delete) all" do
    it do
      expect(item.deleted).to be_blank
      expect(item.histories.count).to eq 1

      login_gws_user to: index_path
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end
      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head label.check input').set(true) }
      within ".list-head-action" do
        page.accept_confirm do
          # find('.disable-all').click
          click_on I18n.t("ss.links.delete")
        end
      end

      wait_for_notice I18n.t('ss.notice.deleted')
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      item.reload
      expect(item.deleted).to be_present

      expect(item.histories.count).to eq 2
      item.histories.first.tap do |history|
        expect(history.name).to eq item.name
        expect(history.mode).to eq "delete"
        expect(history.model).to eq item.class.model_name.i18n_key.to_s
        expect(history.model_name).to eq I18n.t("mongoid.models.#{item.class.model_name.i18n_key}")
        expect(history.item_id).to eq item.id.to_s
        expect(Fs.file?(history.path)).to be_truthy
        expect(history.path).to eq item.histories.last.path
      end
    end

    describe "if user don't have permissions to delete" do
      before do
        user = gws_user
        user.gws_roles.each do |role|
          role.update!(permissions: role.permissions - %w(delete_other_gws_share_files delete_private_gws_share_files))
        end
      end

      it do
        login_gws_user to: index_path
        within ".list-head-action" do
          expect(page).to have_content I18n.t("gws/share.links.file_download")
          expect(page).to have_no_content I18n.t("ss.links.delete")
        end
      end
    end
  end
end
