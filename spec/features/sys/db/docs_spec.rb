require 'spec_helper'

describe "sys_db_docs", type: :feature, dbscope: :example do
  let(:coll) { SS::User.collection_name.to_s }
  let!(:user1) { create(:ss_user, name: "filter-alpha", uid: "filter-alpha", email: "filter-alpha@example.jp") }
  let!(:user2) { create(:ss_user, name: "filter-beta", uid: "filter-beta", email: "filter-beta@example.jp") }
  let!(:user3) { create(:ss_user, name: "other-gamma", uid: "other-gamma", email: "other-gamma@example.jp") }

  before { login_sys_user }

  def search(filter)
    visit sys_db_docs_path(coll: coll)
    within ".list-head" do
      fill_in "s[filter]", with: filter
      click_on I18n.t("ss.buttons.search")
    end
  end

  it "without filter" do
    visit sys_db_docs_path(coll: coll)
    within "table.index" do
      expect(page).to have_css("td", text: user1.name)
      expect(page).to have_css("td", text: user2.name)
      expect(page).to have_css("td", text: user3.name)
    end
  end

  it "with unquoted keys and string value" do
    search("{ name: \"#{user1.name}\" }")
    within "table.index" do
      expect(page).to have_css("td", text: user1.name)
      expect(page).to have_no_css("td", text: user2.name)
      expect(page).to have_no_css("td", text: user3.name)
    end
  end

  it "with operator ($regex)" do
    search('{ name: { $regex: "^filter-" } }')
    within "table.index" do
      expect(page).to have_css("td", text: user1.name)
      expect(page).to have_css("td", text: user2.name)
      expect(page).to have_no_css("td", text: user3.name)
    end
  end

  it "with numeric value and array ($in)" do
    search("{ _id: { $in: [#{user2.id}, #{user3.id}] } }")
    within "table.index" do
      expect(page).to have_no_css("td", text: user1.name)
      expect(page).to have_css("td", text: user2.name)
      expect(page).to have_css("td", text: user3.name)
    end
  end

  it "with extended json date ($date)" do
    user3.set(updated: Time.zone.parse("2000-01-01T00:00:00Z"))
    search('{ name: { $regex: "^(filter|other)-" }, updated: { $lt: { $date: "2001-01-01T00:00:00Z" } } }')
    within "table.index" do
      expect(page).to have_no_css("td", text: user1.name)
      expect(page).to have_no_css("td", text: user2.name)
      expect(page).to have_css("td", text: user3.name)
    end
  end

  it "with invalid syntax" do
    search('{ name: "unterminated }')
    expect(page).to have_no_css("table.index")
    expect(page).to have_css(".list-head", text: /found unexpected end of stream|did not find expected/)
  end

  it "with non-hash filter" do
    search("[1, 2]")
    expect(page).to have_no_css("table.index")
    expect(page).to have_css(".list-head", text: "filter must be a hash")
  end

  it "does not evaluate javascript" do
    search('{ name: (function() { return "filter-alpha" })() }')
    expect(page).to have_no_css("td", text: user1.name)
  end
end
