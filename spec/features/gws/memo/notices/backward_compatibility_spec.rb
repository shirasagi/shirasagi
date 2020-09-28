require 'spec_helper'

describe 'gws/memo/notices', type: :feature, dbscope: :example, js: true do
  context "backward compatibility" do
    let(:site) { gws_site }
    let(:user) { gws_user }
    let(:curcular_item) { create(:gws_circular_post, :gws_circular_posts) }
    let(:curcular_path) { gws_circular_post_path(site: site, category: '-', id: curcular_item) }
    let!(:item_old) do
      SS::Notification.create!(
        cur_group: site, cur_user: user,
        subject: "subject-#{unique_id}", format: "text", text: "text-#{unique_id}" * 10,
        member_ids: [user.id], state: "public"
      )
    end
    let!(:item_new) do
      SS::Notification.create!(
        cur_group: site, cur_user: user,
        subject: "subject-#{unique_id}", format: "text", text: "", url: curcular_path,
        member_ids: [user.id], state: "public"
      )
    end
    let!(:item_no_info) do
      SS::Notification.create!(
        cur_group: site, cur_user: user,
        subject: "subject-#{unique_id}", format: "text", text: "",
        member_ids: [user.id], state: "public"
      )
    end

    before { login_gws_user }

    context "with old version notice" do
      it do
        visit gws_portal_path(site: site)
        within ".gws-memo-notice" do
          expect(page).to have_css(".popup-notice-unseen", text: SS::Notification.count.to_s)
          first(".toggle-popup-notice").click

          within ".popup-notice" do
            expect(page).to have_content(item_old.subject)

            click_on item_old.subject
          end
        end

        expect(page).to have_content(item_old.text)

        item_old.reload
        expect(item_old.user_settings).to be_present
        expect(item_old.user_settings.any? { |user_state| user_state["user_id"] == gws_user.id }).to be_truthy
      end
    end

    context "with new version notice" do
      it do
        visit gws_portal_path(site: site)
        within ".gws-memo-notice" do
          expect(page).to have_css(".popup-notice-unseen", text: SS::Notification.count.to_s)
          first(".toggle-popup-notice").click

          within ".popup-notice" do
            expect(page).to have_content(item_new.subject)

            click_on item_new.subject
          end
        end

        expect(page).to have_content(curcular_item.name)
        expect(page).to have_content(curcular_item.text)

        item_new.reload
        expect(item_new.user_settings).to be_present
        expect(item_new.user_settings.any? { |user_state| user_state["user_id"] == gws_user.id }).to be_truthy
      end
    end

    context "with no information notice" do
      it do
        visit gws_portal_path(site: site)
        within ".gws-memo-notice" do
          expect(page).to have_css(".popup-notice-unseen", text: SS::Notification.count.to_s)
          first(".toggle-popup-notice").click

          wait_for_ajax
          within ".popup-notice" do
            expect(page).to have_content(item_no_info.subject)
            click_on item_no_info.subject
          end
        end

        wait_for_ajax
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.set_seen'))

        item_no_info.reload
        expect(item_no_info.user_settings).to be_present
        expect(item_no_info.user_settings.any? { |user_state| user_state["user_id"] == gws_user.id }).to be_truthy
      end
    end
  end
end
