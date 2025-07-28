require 'spec_helper'

describe "gws_circular_posts", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:now) { Time.zone.now.beginning_of_minute }

  let!(:item1) do
    create(
      :gws_survey_form, state: "public", due_date: now + 1.day,
        readable_setting_range: "select", readable_member_ids: [user.id])
  end
  let!(:item2) do
    create(
      :gws_survey_form, state: "public", due_date: now + 2.days,
        readable_setting_range: "select", readable_member_ids: [user.id])
  end
  let!(:item3) do
    create(
      :gws_survey_form, state: "public", due_date: now + 3.days,
        readable_setting_range: "select", readable_member_ids: [user.id])
  end
  let!(:item4) do
    create(
      :gws_survey_form, state: "public", due_date: now + 4.days,
        readable_setting_range: "select", readable_member_ids: [user.id],
        answered_users_hash: { user.id.to_s => now })
  end
  let!(:item5) do
    create(
      :gws_survey_form, state: "public", due_date: now + 5.days,
        readable_setting_range: "select", readable_member_ids: [user.id],
        answered_users_hash: { user.id.to_s => now })
  end
  let!(:item6) do
    create(
      :gws_survey_form, state: "public", due_date: now + 6.days,
        readable_setting_range: "select", readable_member_ids: [user.id],
        answered_users_hash: { user.id.to_s => now })
  end
  let(:index_path) { gws_survey_main_path(site: site) }

  context "sort by default (site's due_date_asc)" do
    before { login_gws_user }

    it do
      visit index_path

      within ".list-items" do
        expect(all(".list-item").size).to eq 6
        expect(all(".list-item")[0].text).to include(item1.name)
        expect(all(".list-item")[1].text).to include(item2.name)
        expect(all(".list-item")[2].text).to include(item3.name)
        expect(all(".list-item")[3].text).to include(item4.name)
        expect(all(".list-item")[4].text).to include(item5.name)
        expect(all(".list-item")[5].text).to include(item6.name)
      end
    end
  end

  context "sort by due_date_desc" do
    before do
      login_gws_user
      site.survey_sort = "due_date_desc"
      site.update!
    end

    it do
      visit index_path
      within ".list-items" do
        expect(all(".list-item").size).to eq 6
        expect(all(".list-item")[0].text).to include(item6.name)
        expect(all(".list-item")[1].text).to include(item5.name)
        expect(all(".list-item")[2].text).to include(item4.name)
        expect(all(".list-item")[3].text).to include(item3.name)
        expect(all(".list-item")[4].text).to include(item2.name)
        expect(all(".list-item")[5].text).to include(item1.name)
      end
    end
  end
end
