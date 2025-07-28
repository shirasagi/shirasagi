require 'spec_helper'

describe "gws_circular_posts", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:now) { Time.zone.now.beginning_of_minute }

  let!(:post1) do
    create(:gws_circular_post, due_date: now + 1.day, member_ids: [user.id], state: "public")
  end
  let!(:post2) do
    create(:gws_circular_post, due_date: now + 2.days, member_ids: [user.id], state: "public")
  end
  let!(:post3) do
    create(:gws_circular_post, due_date: now + 3.days, member_ids: [user.id], state: "public")
  end
  let!(:post4) do
    create(:gws_circular_post, due_date: now + 4.days, member_ids: [user.id], state: "public",
      seen: { user.id.to_s => now })
  end
  let!(:post5) do
    create(:gws_circular_post, due_date: now + 5.days, member_ids: [user.id], state: "public",
      seen: { user.id.to_s => now })
  end
  let!(:post6) do
    create(:gws_circular_post, due_date: now + 6.days, member_ids: [user.id], state: "public",
      seen: { user.id.to_s => now })
  end
  let(:index_path) { gws_circular_main_path(site: site) }

  context "sort by default (site's due_date_asc)" do
    before { login_gws_user }

    it do
      visit index_path
      within ".list-items" do
        expect(all(".list-item").size).to eq 6
        expect(all(".list-item")[0].text).to include(post1.name)
        expect(all(".list-item")[1].text).to include(post2.name)
        expect(all(".list-item")[2].text).to include(post3.name)
        expect(all(".list-item")[3].text).to include(post4.name)
        expect(all(".list-item")[4].text).to include(post5.name)
        expect(all(".list-item")[5].text).to include(post6.name)
      end
    end
  end

  context "sort by due_date_desc" do
    before do
      login_gws_user
      site.circular_sort = "due_date_desc"
      site.update!
    end

    it do
      visit index_path
      within ".list-items" do
        expect(all(".list-item").size).to eq 6
        expect(all(".list-item")[0].text).to include(post6.name)
        expect(all(".list-item")[1].text).to include(post5.name)
        expect(all(".list-item")[2].text).to include(post4.name)
        expect(all(".list-item")[3].text).to include(post3.name)
        expect(all(".list-item")[4].text).to include(post2.name)
        expect(all(".list-item")[5].text).to include(post1.name)
      end
    end
  end
end
