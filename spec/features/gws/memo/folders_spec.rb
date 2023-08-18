require 'spec_helper'

describe 'gws_memo_folders', type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let!(:site) { gws_site }
    let!(:item) { create :gws_memo_folder }
    let!(:child_item) { create :gws_memo_folder, name: "#{item.name}/child" }
    let!(:message) { create :gws_memo_message }
    let!(:index_path) { gws_memo_folders_path site }
    let!(:new_path) { new_gws_memo_folder_path site }
    let!(:show_path) { gws_memo_folder_path site, item }
    let!(:edit_path) { edit_gws_memo_folder_path site, item }
    let!(:delete_path) { delete_gws_memo_folder_path site, item }

    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path

      name = "name-#{unique_id}"
      click_link I18n.t('gws/share.apis.folders.index')
      click_link item.name
      within "form#item-form" do
        fill_in "item[in_basename]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      expect(first('#addon-basic')).to have_text(name)
    end

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path

      name = "modify-#{unique_id}"
      within "form#item-form" do
        fill_in "item[in_basename]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      expect(first('#addon-basic')).to have_text(name)
    end

    it "#delete" do
      visit delete_path
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end

    describe "#create" do
      before { visit new_path }

      context "parent exists" do
        it "creates a child" do
          within "form#item-form" do
            fill_in "item[in_basename]", with: "#{item.name}/childs"
            within ""
            expect{ click_button I18n.t('ss.buttons.save') }.to change { Gws::Memo::Folder.count }.by(1)
          end
          expect(current_path).to eq gws_memo_folder_path site, Gws::Memo::Folder
                                    .where(name: "#{item.name}/childs").first
        end
      end

      context "parent does'nt exist" do
        it "does'nt create a child" do
          within "form#item-form" do
            fill_in "item[in_basename]", with: "test/child"
            expect{ click_button I18n.t('ss.buttons.save') }.not_to(change { Gws::Memo::Folder.count })
          end
          expect(current_path).to eq gws_memo_folders_path site
        end
      end
    end

    describe "#update" do
      before{ visit edit_path }
      it "is updated" do
        name = "modify-#{unique_id}"
        within "form#item-form" do
          fill_in "item[in_basename]", with: name
          click_button I18n.t('ss.buttons.save')
        end
        expect(first('#addon-basic')).to have_text(name)
      end

      context "parent_name updates" do
        before do
          child_item
          visit edit_path
        end

        it "is updated" do
          name = "modify-#{unique_id}"
          modify_child_name = "#{name}/child"
          within "form#item-form" do
            fill_in "item[in_basename]", with: name
            expect do
              click_button I18n.t('ss.buttons.save')
            end.to change { Gws::Memo::Folder.find(item.id).name }.from(item.name).to(name)
               .and change { Gws::Memo::Folder.find(child_item.id).name }.from(child_item.name).to(modify_child_name)
          end
          visit index_path
          expect(page).to have_link(name)
          expect(page).to have_link(modify_child_name)
        end
      end

      context "update with blank parent_name" do
        before { visit edit_gws_memo_folder_path site, child_item }

        it "is not updated" do
          modify_child_name = "test/child"
          within "form#item-form" do
            fill_in "item[in_basename]", with: modify_child_name
            expect{ click_button I18n.t('ss.buttons.save') }.not_to(change { Gws::Memo::Folder.find(child_item.id).name })
          end
        end
      end
    end

    describe "#destroy" do
      before do
        child_item
        visit delete_path
      end

      context "child does'nt have any message" do
        it "has destroyed" do
          within "form#item-form" do
            expect{ click_button I18n.t('ss.buttons.delete') }.to change { Gws::Memo::Folder.count }.by(-2)
          end
          expect(current_path).to eq index_path
          expect(Gws::Memo::Folder.where(name: item.name).first).to be_blank
          expect(Gws::Memo::Folder.where(name: child_item.name).first).to be_blank
        end
      end

      context "parent has some messages" do
        before do
          message.move(gws_user, item.folder_path)
          message.save
        end

        it "both child and parent are not destroyed" do
          within "form#item-form" do
            expect { click_button I18n.t('ss.buttons.delete') }.not_to(change { Gws::Memo::Folder.count })
          end
        end
      end

      context "child has some messages" do
        before do
          message.move(gws_user, child_item.folder_path)
          message.save
        end

        it "are not destroyed" do
          within "form#item-form" do
            expect{ click_button I18n.t('ss.buttons.delete') }.not_to(change { Gws::Memo::Folder.count })
          end
        end
      end
    end
  end
end
