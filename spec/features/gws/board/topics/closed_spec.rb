require 'spec_helper'

describe "gws_board_topics", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let(:site) { gws_site }
    let!(:user1) do
      create(
        :gws_user, notice_board_email_user_setting: "notify", send_notice_mail_addresses: "#{unique_id}@example.jp",
        group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
      )
    end
    let!(:category) { create :gws_board_category, subscribed_member_ids: [ user1.id ] }
    let(:index_path) { gws_board_topics_path site, '-', '-' }
    let(:now) { Time.zone.at(Time.zone.now.to_i) }

    before do
      site.canonical_scheme = %w(http https).sample
      site.canonical_domain = "#{unique_id}.example.jp"
      site.save!

      login_gws_user

      ActionMailer::Base.deliveries.clear
    end

    after { ActionMailer::Base.deliveries.clear }

    describe "#new" do
      it do
        visit index_path
        click_on I18n.t("ss.navi.editable")
        click_on I18n.t("ss.links.new")
        click_on I18n.t("gws.apis.categories.index")
        wait_for_cbox do
          click_on category.name
        end

        within "form#item-form" do
          within "#addon-basic" do
            fill_in "item[name]", with: "name"
          end

          within "#addon-ss-agents-addons-markdown" do
            select I18n.t("ss.options.text_type.markdown"), from: "item[text_type]"
            fill_in "item[text]", with: "markdown"
          end

          within "#addon-gws-agents-addons-board-notify_setting" do
            select I18n.t("ss.options.state.enabled"), from: "item[notify_state]"
          end

          within "#addon-gws-agents-addons-release" do
            first(".addon-head h2").click
            select I18n.t("ss.options.state.closed"), from: "item[state]"
          end

          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

        item = Gws::Board::Topic.site(site).first
        expect(item.name).to eq "name"
        expect(item.text).to eq "markdown"
        expect(item.text_type).to eq "markdown"
        expect(item.notify_state).to eq "enabled"
        expect(item.state).to eq "closed"
        expect(item.mode).to eq "thread"
        expect(item.descendants_updated).to be_present
        expect(item.descendants_files_count).to eq 0
        expect(item.category_ids).to eq [category.id]

        expect(SS::Notification.all.count).to eq 0
        expect(ActionMailer::Base.deliveries.length).to eq 0
      end
    end

    context "with item" do
      let!(:item) { create :gws_board_topic, category_ids: [ category.id ], notify_state: "enabled", state: "closed" }

      describe "#edit" do
        it do
          visit index_path
          click_on I18n.t("ss.navi.editable")
          click_on item.name
          click_on I18n.t("ss.links.edit")
          within "form#item-form" do
            fill_in "item[name]", with: "modify"
            click_on I18n.t("ss.buttons.save")
          end
          expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

          item.reload
          expect(item.name).to eq "modify"
          expect(item.category_ids).to include(category.id)

          expect(SS::Notification.all.count).to eq 0
          expect(ActionMailer::Base.deliveries.length).to eq 0
        end
      end

      describe "#soft_delete" do
        it do
          visit index_path
          click_on I18n.t("ss.navi.editable")
          click_on item.name
          click_on I18n.t("ss.links.delete")
          within "form" do
            click_button I18n.t("ss.buttons.delete")
          end
          expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

          item.reload
          expect(item.deleted).to be_present

          expect(SS::Notification.all.count).to eq 0
          expect(ActionMailer::Base.deliveries.length).to eq 0
        end
      end

      describe "#hard_delete" do
        before do
          item.deleted = now
          item.save!
        end

        it do
          visit index_path
          click_on I18n.t("ss.links.trash")
          click_on item.name
          click_on I18n.t("ss.links.delete")
          within "form" do
            click_button I18n.t("ss.buttons.delete")
          end
          expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

          expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
          expect(SS::Notification.all.count).to eq 0
          expect(ActionMailer::Base.deliveries.length).to eq 0
        end
      end

      describe "#undo_delete" do
        before do
          item.deleted = now
          item.save!
        end

        it do
          visit index_path
          click_on I18n.t("ss.links.trash")
          click_on item.name
          click_on I18n.t("ss.links.restore")
          within "form" do
            click_button I18n.t("ss.buttons.restore")
          end
          expect(page).to have_css("#notice", text: I18n.t("ss.notice.restored"))

          item.reload
          expect(item.deleted).to be_blank

          expect(SS::Notification.all.count).to eq 0
          expect(ActionMailer::Base.deliveries.length).to eq 0
        end
      end
    end
  end
end
