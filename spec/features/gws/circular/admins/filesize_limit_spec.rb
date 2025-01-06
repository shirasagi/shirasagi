require 'spec_helper'

describe "gws_circular_admins", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let(:name) { unique_id }
  let!(:file_path) { tmpfile(extname: ".txt") { |f| f.puts Array.new(rand(3..10)) { unique_id }.join("\n") } }
  let!(:file_size) { File.size(file_path) }

  before do
    site.circular_filesize_limit = limit
    site.save!

    allow_any_instance_of(Gws::Group).to receive(:circular_filesize_limit_in_bytes).and_return(limit)
  end

  context "when attached file is within the limit" do
    let!(:limit) { file_size }

    before { login_gws_user }

    it do
      # Create as draft
      visit gws_circular_admins_path(site)
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: name
      end

      # attach file
      within "form#item-form" do
        within "#addon-gws-agents-addons-file" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.buttons.upload")
          end
        end
      end
      within_cbox do
        attach_file "item[in_files][]", file_path
        wait_for_cbox_closed { click_on I18n.t("ss.buttons.attach") }
      end

      # choose member
      within "form#item-form" do
        within "#addon-gws-agents-addons-member" do
          wait_for_cbox_opened { click_on I18n.t("ss.apis.users.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on user1.name }
      end

      # save as draft
      within "form#item-form" do
        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(Gws::Circular::Post.all.topic.count).to eq 1
      Gws::Circular::Post.all.topic.first.tap do |topic|
        expect(topic.name).to eq name
        expect(topic.files.count).to eq 1
        topic.files.first.tap do |topic_file|
          expect(topic_file.name).to eq File.basename(file_path)
          expect(topic_file.filename).to eq File.basename(file_path)
          expect(topic_file.site_id).to be_blank
          expect(topic_file.model).to eq "gws/circular/post"
          expect(topic_file.owner_item_id).to eq topic.id
          expect(topic_file.owner_item_type).to eq topic.class.name
        end
      end

      expect(SS::Notification.all.count).to eq 0
    end
  end

  context "when attached file is over the limit" do
    let!(:limit) { file_size - 1 }

    before { login_gws_user }

    it do
      # Create as draft
      visit gws_circular_admins_path(site)
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: name
      end

      # attach file
      within "form#item-form" do
        within "#addon-gws-agents-addons-file" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.buttons.upload")
          end
        end
      end
      within_cbox do
        attach_file "item[in_files][]", file_path
        wait_for_cbox_closed { click_on I18n.t("ss.buttons.attach") }
      end

      # choose member
      within "form#item-form" do
        within "#addon-gws-agents-addons-member" do
          wait_for_cbox_opened { click_on I18n.t("ss.apis.users.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on user1.name }
      end

      # save as draft
      within "form#item-form" do
        click_on I18n.t("ss.buttons.draft_save")
      end
      msg = I18n.t(
        "mongoid.errors.models.gws/circular/post.file_size_limit",
        size: file_size.to_fs(:human_size), limit: limit.to_fs(:human_size)
      )
      expect(page).to have_css("#errorExplanation", text: msg)

      expect(Gws::Circular::Post.all.topic.count).to eq 0

      expect(SS::Notification.all.count).to eq 0
    end
  end
end
