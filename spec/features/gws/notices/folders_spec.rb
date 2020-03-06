require 'spec_helper'

describe "gws_notice_folders", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  before { login_gws_user }

  context "basic crud" do
    let(:name) { unique_id }
    let(:order) { rand(1..10) }
    let(:name2) { unique_id }

    it do
      #
      # Create
      #
      visit gws_notice_folders_path(site: site)
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[in_basename]", with: name
        fill_in "item[order]", with: order

        within "#addon-gws-agents-addons-member" do
          click_on I18n.t("ss.apis.users.index")
        end
      end
      wait_for_cbox do
        click_on gws_user.name
      end
      within "form#item-form" do
        within "#addon-gws-agents-addons-member" do
          expect(page).to have_content(gws_user.name)
        end

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect(Gws::Notice::Folder.all.count).to eq 1
      Gws::Notice::Folder.all.first.tap do |folder|
        expect(folder.name).to eq name
        expect(folder.order).to eq order
        expect(folder.member_ids).to include(gws_user.id)
        expect(folder.depth).to eq 1
      end

      #
      # Update
      #
      visit gws_notice_folders_path(site: site)
      click_on name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[in_basename]", with: name2
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect(Gws::Notice::Folder.all.count).to eq 1
      Gws::Notice::Folder.all.first.tap do |cate|
        expect(cate.name).to eq name2
        expect(cate.order).to eq order
      end

      #
      # Delete
      #
      visit gws_notice_folders_path(site: site)
      click_on name2
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

      expect(Gws::Notice::Folder.all.count).to eq 0
    end
  end

  context "sub folder" do
    context "basic crud" do
      let!(:folder0) { create(:gws_notice_folder) }
      let(:name) { unique_id }
      let(:order) { rand(1..10) }
      let(:name2) { unique_id }

      it do
        #
        # Create
        #
        visit gws_notice_folders_path(site: site)
        click_on I18n.t("ss.links.new")
        within "form#item-form" do
          fill_in "item[in_basename]", with: name
          fill_in "item[order]", with: order
          within "#addon-basic" do
            click_on I18n.t("gws/share.apis.folders.index")
          end
        end
        wait_for_cbox do
          click_on folder0.name
        end
        within "form#item-form" do
          within "#addon-gws-agents-addons-member" do
            click_on I18n.t("ss.apis.users.index")
          end
        end
        wait_for_cbox do
          click_on gws_user.name
        end
        within "form#item-form" do
          within "#addon-gws-agents-addons-member" do
            expect(page).to have_content(gws_user.name)
          end

          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

        expect(Gws::Notice::Folder.all.count).to eq 2
        Gws::Notice::Folder.all.reorder(created: -1).first.tap do |folder|
          expect(folder.name).to eq "#{folder0.name}/#{name}"
          expect(folder.order).to eq order
          expect(folder.member_ids).to include(gws_user.id)
          expect(folder.depth).to eq 2
        end

        #
        # Update
        #
        visit gws_notice_folders_path(site: site)
        click_on "#{folder0.name}/#{name}"
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          fill_in "item[in_basename]", with: name2
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

        expect(Gws::Notice::Folder.all.count).to eq 2
        Gws::Notice::Folder.all.reorder(created: -1).first.tap do |cate|
          expect(cate.name).to eq "#{folder0.name}/#{name2}"
          expect(cate.order).to eq order
        end

        #
        # Delete
        #
        visit gws_notice_folders_path(site: site)
        click_on "#{folder0.name}/#{name2}"
        click_on I18n.t("ss.links.delete")
        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

        expect(Gws::Notice::Folder.all.count).to eq 1
      end
    end

    context "when parent folder is not exist" do
      it do
        visit gws_notice_folders_path(site: site)
        click_on I18n.t("ss.links.new")
        within "form#item-form" do
          fill_in "item[in_basename]", with: "#{unique_id}/#{unique_id}"

          within "#addon-gws-agents-addons-member" do
            click_on I18n.t("ss.apis.users.index")
          end
        end
        wait_for_cbox do
          click_on gws_user.name
        end
        within "form#item-form" do
          within "#addon-gws-agents-addons-member" do
            expect(page).to have_content(gws_user.name)
          end

          click_on I18n.t("ss.buttons.save")
        end
        within "#errorExplanation" do
          error = [
            I18n.t("mongoid.attributes.gws/model/folder.name"),
            I18n.t("mongoid.errors.models.gws/model/folder.invalid_chars_as_name")
          ].join
          expect(page).to have_css("li", text: error)
          expect(page).to have_css("li", text: I18n.t("mongoid.errors.models.gws/model/folder.not_found_parent"))
        end
      end
    end
  end

  context "move" do
    let!(:folder0) { create(:gws_notice_folder) }
    let!(:folder1) { create(:gws_notice_folder) }
    let(:name) { unique_id }
    let!(:item) { create(:gws_notice_folder, name: "#{folder0.name}/#{name}") }

    it do
      visit gws_notice_folders_path(site: site)
      click_on item.name
      click_on I18n.t("ss.links.move")
      within "form#item-form" do
        click_on I18n.t("gws/share.apis.folders.index")
      end
      wait_for_cbox do
        click_on folder1.name
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.moved"))

      item.reload
      expect(item.name).to eq "#{folder1.name}/#{name}"
    end
  end

  context "reclaim" do
    let!(:item) { create(:gws_notice_folder) }
    let(:file) do
      filename = "#{Rails.root}/spec/fixtures/ss/logo.png"
      basename = ::File.basename(filename)
      SS::File.create_empty!(
        cur_user: gws_user, name: basename, filename: basename,
        content_type: "image/png", model: 'ss/temp_file'
      ) do |file|
        ::FileUtils.cp(filename, file.path)
      end
    end

    it do
      visit gws_notice_folders_path(site: site)
      click_on item.name

      expect(file).to be_valid
      post = create(:gws_notice_post, folder: item, name: "a" * 8, text: "b" * 15, file_ids: [ file.id ])
      expect(post).to be_valid

      item.reload
      expect(item.notices.count).to eq 1
      expect(SS::File.in(id: item.notices.pluck(:file_ids).flatten).sum(:size)).to be > 0

      first("button[name='reclaim_total_size']").click
      expect(page).to have_css("#notice", text: I18n.t("gws/notice.notice.reclaimed"))

      usage1 = I18n.t("gws/notice.total_body_size_current_stats", size: post.text.size.to_s(:human_size), percentage: "0.00%")
      expect(page).to have_content(usage1)
      usage2 = I18n.t("gws/notice.total_body_size_current_stats", size: file.size.to_s(:human_size), percentage: "0.04%")
      expect(page).to have_content(usage2)
    end
  end
end
