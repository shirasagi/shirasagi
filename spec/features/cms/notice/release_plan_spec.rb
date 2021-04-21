require 'spec_helper'

describe "cms_notices", type: :feature, dbscope: :example do
  let!(:current) { Time.zone.now.beginning_of_minute }
  let!(:release_date) { current + 1.day }
  let!(:close_date) { release_date + 1.day }
  let!(:notice0) do
    create(
      :cms_notice, cur_site: cms_site, state: "public", notice_severity: "high", notice_target: Cms::Notice::NOTICE_TARGET_ALL,
      release_date: release_date, close_date: close_date
    )
  end
  let!(:notice1) do
    create(
      :cms_notice, cur_site: cms_site, state: "public", notice_severity: "normal", notice_target: Cms::Notice::NOTICE_TARGET_ALL,
      release_date: release_date, close_date: close_date
    )
  end

  before do
    cms_site
    cms_user
  end

  context "just before release" do
    it do
      Timecop.freeze(release_date - 1.second) do
        login_cms_user
        visit cms_contents_path(site: cms_site)
        expect(page).to have_no_css(".notices")
      end
    end
  end

  context "at release" do
    it do
      Timecop.freeze(release_date) do
        login_cms_user
        visit cms_contents_path(site: cms_site)
        within ".notices" do
          expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
          expect(page).to have_css(".list-item .notice-severity-normal", text: notice1.name)
        end
      end
    end
  end

  context "just before closed" do
    it do
      Timecop.freeze(close_date - 1.second) do
        login_cms_user
        visit cms_contents_path(site: cms_site)
        within ".notices" do
          expect(page).to have_css(".list-item .notice-severity-high", text: notice0.name)
          expect(page).to have_css(".list-item .notice-severity-normal", text: notice1.name)
        end
      end
    end
  end

  context "at closed" do
    it do
      Timecop.freeze(close_date) do
        login_cms_user
        visit cms_contents_path(site: cms_site)
        expect(page).to have_no_css(".notices")
      end
    end
  end
end
