require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:memo1) do
    Timecop.freeze(now - 5.minutes) do
      create(
        :gws_memo_message, user: user, site: site, subject: ss_japanese_text, text: ss_japanese_text,
        in_to_members: [user.id.to_s]
      )
    end
  end
  let!(:memo2) do
    Timecop.freeze(now - 10.minutes) do
      create(
        :gws_memo_message, user: user, site: site, subject: ss_japanese_text, text: ss_japanese_text,
        in_to_members: [user.id.to_s]
      )
    end
  end
  let!(:memo3) do
    Timecop.freeze(now - 15.minutes) do
      create(
        :gws_memo_message, user: user, site: site, subject: ss_japanese_text, text: ss_japanese_text,
        in_to_members: [user.id.to_s]
      )
    end
  end
  let!(:memo4) do
    Timecop.freeze(now - 20.minutes) do
      create(
        :gws_memo_message, user: user, site: site, subject: ss_japanese_text, text: ss_japanese_text,
        in_to_members: [user.id.to_s]
      )
    end
  end

  before do
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!

    login_gws_user
  end

  context "prev / next navigation" do
    it do
      visit gws_memo_messages_path(site)
      wait_for_js_ready

      # 日付順にならんでいるはず
      all(".list-item").tap do |list_items|
        expect(list_items.length).to eq 4
        within list_items[0] do
          expect(page).to have_css(".title", text: memo1.subject)
        end
        within list_items[1] do
          expect(page).to have_css(".title", text: memo2.subject)
        end
        within list_items[2] do
          expect(page).to have_css(".title", text: memo3.subject)
        end
        within list_items[3] do
          expect(page).to have_css(".title", text: memo4.subject)
        end
      end

      click_on memo3.subject
      wait_for_js_ready

      within ".move-tool-wrap" do
        expect(page).to have_css(".page-order", text: "3 / 4")
        click_on "arrow_circle_right"
      end
      wait_for_js_ready

      expect(page).to have_css(".subject", text: memo4.subject)
      within ".move-tool-wrap" do
        expect(page).to have_css(".page-order", text: "4 / 4")
        expect(page).to have_css(".next.inactive", text: "arrow_circle_right")
        click_on "arrow_circle_left"
      end
      wait_for_js_ready

      expect(page).to have_css(".subject", text: memo3.subject)
      within ".move-tool-wrap" do
        expect(page).to have_css(".page-order", text: "3 / 4")
        click_on "arrow_circle_left"
      end
      wait_for_js_ready

      expect(page).to have_css(".subject", text: memo2.subject)
      within ".move-tool-wrap" do
        expect(page).to have_css(".page-order", text: "2 / 4")
        click_on "arrow_circle_left"
      end
      wait_for_js_ready

      expect(page).to have_css(".subject", text: memo1.subject)
      within ".move-tool-wrap" do
        expect(page).to have_css(".page-order", text: "1 / 4")
        expect(page).to have_css(".prev.inactive", text: "arrow_circle_left")
      end
    end
  end
end
