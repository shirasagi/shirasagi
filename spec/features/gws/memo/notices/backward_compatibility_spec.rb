require 'spec_helper'

describe 'gws/memo/notices', type: :feature, dbscope: :example, js: true do
  context "backward compatibility" do
    let(:site) { gws_site }
    let(:user) { gws_user }
    let(:curcular_item) { create(:gws_circular_post, :gws_circular_posts) }
    let(:curcular_path) { gws_circular_post_path(site: site, category: '-', id: curcular_item) }
    let!(:item_old) do
      Gws::Memo::Notice.create!(
        cur_site: site, cur_user: user,
        subject: "subject-#{unique_id}", format: "text", text: "text-#{unique_id}" * 10,
        member_ids: [user.id], state: "public", export: false
      )
    end
    let!(:item_new) do
      Gws::Memo::Notice.create!(
        cur_site: site, cur_user: user,
        subject: "subject-#{unique_id}", format: "text", text: "", url: curcular_path,
        member_ids: [user.id], state: "public", export: false
      )
    end
    let!(:item_no_info) do
      Gws::Memo::Notice.create!(
        cur_site: site, cur_user: user,
        subject: "subject-#{unique_id}", format: "text", text: "",
        member_ids: [user.id], state: "public", export: false
      )
    end

    before { login_gws_user }

    context "with old version notice" do
      it do
        visit gws_portal_path(site: site)
        within ".gws-memo-notice" do
          expect(page).to have_css(".popup-notice-unseen", text: Gws::Memo::Notice.count.to_s)
          first(".toggle-popup-notice").click

          within ".popup-notice" do
            expect(page).to have_content(item_old.subject)

            click_on item_old.subject
          end
        end

        expect(page).to have_content(item_old.text)

        item_old.reload
        expect(item_old.seen).to be_present
        expect(item_old.seen[gws_user.id.to_s]).to be_present
      end
    end

    context "with new version notice" do
      it do
        visit gws_portal_path(site: site)
        within ".gws-memo-notice" do
          expect(page).to have_css(".popup-notice-unseen", text: Gws::Memo::Notice.count.to_s)
          first(".toggle-popup-notice").click

          within ".popup-notice" do
            expect(page).to have_content(item_new.subject)

            click_on item_new.subject
          end
        end

        expect(page).to have_content(curcular_item.name)
        expect(page).to have_content(curcular_item.text)

        item_new.reload
        expect(item_new.seen).to be_present
        expect(item_new.seen[gws_user.id.to_s]).to be_present
      end
    end

    context "with no information notice" do
      it do
        visit gws_portal_path(site: site)
        within ".gws-memo-notice" do
          expect(page).to have_css(".popup-notice-unseen", text: Gws::Memo::Notice.count.to_s)
          first(".toggle-popup-notice").click

          within ".popup-notice" do
            expect(page).to have_content(item_no_info.subject)

            click_on item_no_info.subject
          end
        end

        expect(page).to have_css('#notice', text: I18n.t('gws/circular.notice.set_seen'))

        item_no_info.reload
        expect(item_no_info.seen).to be_present
        expect(item_no_info.seen[gws_user.id.to_s]).to be_present
      end
    end
  end
end
