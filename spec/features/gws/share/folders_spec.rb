require 'spec_helper'

describe "gws_share_folders", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  context "basic crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }

    before { login_gws_user }

    it do
      #
      # Create
      #
      visit gws_share_folders_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        fill_in "item[in_basename]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Share::Folder.all.count).to eq 1
      folder = Gws::Share::Folder.all.first
      expect(folder.site_id).to eq site.id
      expect(folder.name).to eq name
      expect(folder.depth).to eq 1
      expect(folder.order).to eq 0
      expect(folder.share_max_file_size).to eq 0
      expect(folder.share_max_folder_size).to eq 0
      expect(folder.readable_setting_range).to eq "select"
      expect(folder.readable_group_ids).to eq gws_user.groups.pluck(:id)
      expect(folder.readable_member_ids).to eq [ gws_user.id ]
      expect(folder.readable_custom_group_ids).to be_blank
      expect(folder.group_ids).to eq folder.readable_group_ids
      expect(folder.user_ids).to eq folder.readable_member_ids
      expect(folder.custom_group_ids).to be_blank
      expect(folder.permission_level).to eq 1

      #
      # Update
      #
      visit gws_share_folders_path(site: site)
      click_on name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[in_basename]", with: name2
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      folder.reload
      expect(folder.name).to eq name2

      #
      # Delete
      #
      visit gws_share_folders_path(site: site)
      click_on name2
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect { Gws::Share::Folder.find(folder.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "with sub folder" do
    let(:subfolder_name1) { unique_id }
    let(:subfolder_name2) { unique_id }
    let(:item) { create :gws_share_folder }
    let(:item2) { create :gws_share_folder }
    let(:group1) { create :gws_group, name: "#{gws_site.name}/#{unique_id}" }
    let(:group2) { create :gws_group, name: "#{gws_site.name}/#{unique_id}" }
    let(:user1) { create :gws_user, group_ids: [ group1.id ] }
    let(:user2) { create :gws_user, group_ids: [ group2.id ] }

    before { login_gws_user }

    before do
      item.readable_group_ids += [ group1.id ]
      item.readable_member_ids += [ user1.id ]
      item.group_ids += [ group2.id ]
      item.user_ids += [ user2.id ]
      item.save!

      item2
    end

    context 'basic crud' do
      it do
        visit gws_share_folders_path(site: site)
        within ".nav-menu" do
          click_on I18n.t('ss.links.new')
        end

        #
        # Create
        #
        within 'form#item-form' do
          fill_in 'item[in_basename]', with: subfolder_name1
          wait_for_cbox_opened do
            click_on I18n.t('gws/share.apis.folders.index')
          end
        end

        within_cbox do
          wait_for_cbox_closed do
            click_on item.name
          end
        end

        within 'form#item-form' do
          expect(page).to have_css(".ajax-selected", text: item.name)
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name1}").count).to eq 1
        Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name1}").first.tap do |folder|
          # these fields inherit from its parent
          expect(folder.readable_group_ids).to include(group1.id)
          expect(folder.readable_member_ids).to include(user1.id)
          expect(folder.group_ids).to include(group2.id)
          expect(folder.user_ids).to include(user2.id)
        end

        #
        # Update
        #
        visit gws_share_folders_path(site: site)
        click_on "#{item.name}/#{subfolder_name1}"
        within ".nav-menu" do
          click_on I18n.t('ss.links.edit')
        end
        within 'form#item-form' do
          fill_in 'item[in_basename]', with: subfolder_name2
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name1}").count).to eq 0
        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name2}").count).to eq 1

        #
        # Delete
        #
        visit gws_share_folders_path(site: site)
        click_on "#{item.name}/#{subfolder_name2}"
        within ".nav-menu" do
          click_on I18n.t('ss.links.delete')
        end
        within 'form#item-form' do
          click_on I18n.t('ss.buttons.delete')
        end
        wait_for_notice I18n.t('ss.notice.deleted')

        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name1}").count).to eq 0
        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name2}").count).to eq 0
      end
    end

    context 'move sub folder' do
      let!(:sub_folder) { create(:gws_share_folder, name: "#{item.name}/#{subfolder_name1}") }

      it do
        visit gws_share_folders_path(site: site)
        click_on "#{item.name}/#{subfolder_name1}"
        within ".nav-menu" do
          click_on I18n.t('ss.links.move')
        end
        within 'form#item-form' do
          wait_for_cbox_opened { click_on I18n.t('gws/share.apis.folders.index') }
        end
        within_cbox do
          expect(page).to have_content(item2.name)
          wait_for_cbox_closed { click_on item2.name }
        end
        within 'form#item-form' do
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name1}").count).to eq 0
        expect(Gws::Share::Folder.site(site).where(name: "#{item2.name}/#{subfolder_name1}").count).to eq 1
      end
    end

    context 'move folder with sub folder' do
      let!(:sub_folder) { create(:gws_share_folder, name: "#{item.name}/#{subfolder_name1}") }

      it do
        visit gws_share_folders_path(site: site)
        find("a.title[href=\"#{gws_share_folder_path(site, item)}\"]").click
        within ".nav-menu" do
          click_on I18n.t('ss.links.move')
        end
        within 'form#item-form' do
          wait_for_cbox_opened { click_on I18n.t('gws/share.apis.folders.index') }
        end
        within_cbox do
          expect(page).to have_content(item2.name)
          wait_for_cbox_closed { click_on item2.name }
        end
        within 'form#item-form' do
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        expect(Gws::Share::Folder.site(site).where(name: item.name).count).to eq 0
        expect(Gws::Share::Folder.site(site).where(name: "#{item.name}/#{subfolder_name1}").count).to eq 0
        expect(Gws::Share::Folder.site(site).where(name: "#{item2.name}/#{item.name}").count).to eq 1
        expect(Gws::Share::Folder.site(site).where(name: "#{item2.name}/#{item.name}/#{subfolder_name1}").count).to eq 1
      end
    end
  end

  describe "download" do
    let!(:folder) { create :gws_share_folder }
    let!(:category) { create :gws_share_category }
    let!(:file) { create :gws_share_file, folder_id: folder.id, category_ids: [category.id] }

    before { login_gws_user }

    context "when zip file is created on the fly" do
      it do
        visit gws_share_folders_path(site: site)
        click_on folder.name
        within "#addon-basic" do
          page.accept_confirm do
            click_on I18n.t("ss.buttons.download")
          end
        end

        wait_for_download

        entry_names = Zip::File.open(downloads.first) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to include(file.name)
      end
    end

    context "when zip file is created in background job" do
      before do
        @save_config = SS.config.env.deley_download
        SS.config.replace_value_at(:env, :deley_download, { "min_filesize" => 0, "min_count" => 0 })
      end

      after do
        SS.config.replace_value_at(:env, :deley_download, @save_config)
      end

      it do
        visit gws_share_folders_path(site: site)
        click_on folder.name
        within "#addon-basic" do
          page.accept_confirm do
            click_on I18n.t("ss.buttons.download")
          end
        end
        wait_for_notice I18n.t('gws.notice.delay_download_with_message').split("\n").first

        expect(enqueued_jobs.size).to eq 1
        enqueued_jobs.first.tap do |enqueued_job|
          expect(enqueued_job[:job]).to eq Gws::CompressJob
          expect(enqueued_job[:args].first).to include("model" => "Gws::Share::File", "items" => [file.id])
        end
      end
    end
  end
end
