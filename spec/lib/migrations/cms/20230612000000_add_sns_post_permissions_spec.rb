require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20230612000000_add_sns_post_permissions.rb")

RSpec.describe SS::Migration20230612000000, dbscope: :example do
  let(:site) { cms_site }
  let(:site2) { create :cms_site_unique, group_ids: site.group_ids }
  let(:site3) { create :cms_site_unique, group_ids: site.group_ids }

  let!(:role1) { create :cms_role, site: site, permissions: %w(release_private_cms_pages) }
  let!(:role2) { create :cms_role, site: site, permissions: %w(edit_private_cms_pages) }
  let!(:role3) { create :cms_role, site: site2, permissions: %w(release_private_cms_pages) }
  let!(:role4) { create :cms_role, site: site2, permissions: %w(edit_private_cms_pages) }
  let!(:role5) { create :cms_role, site: site3, permissions: %w(release_private_cms_pages) }
  let!(:role6) { create :cms_role, site: site3, permissions: %w(edit_private_cms_pages) }

  let(:permission1) { "use_cms_page_line_posts" }
  let(:permission2) { "use_cms_page_twitter_posts" }

  before do
    site2.line_poster_state = "enabled"
    site2.line_channel_secret = unique_id
    site2.line_channel_access_token = unique_id
    site2.save!

    site3.twitter_poster_state = "enabled"
    site3.twitter_username = unique_id
    site3.twitter_consumer_key = unique_id
    site3.twitter_consumer_secret = unique_id
    site3.twitter_access_token = unique_id
    site3.twitter_access_token_secret = unique_id
    site3.save!

    described_class.new.change
  end

  it do
    role1.reload
    role2.reload
    role3.reload
    role4.reload
    role5.reload
    role6.reload

    expect(role1.permissions.include?(permission1)).to be false
    expect(role1.permissions.include?(permission2)).to be false
    expect(role2.permissions.include?(permission1)).to be false
    expect(role2.permissions.include?(permission2)).to be false
    expect(role3.permissions.include?(permission1)).to be false
    expect(role3.permissions.include?(permission2)).to be false
    expect(role4.permissions.include?(permission1)).to be true
    expect(role4.permissions.include?(permission2)).to be false
    expect(role5.permissions.include?(permission1)).to be false
    expect(role5.permissions.include?(permission2)).to be false
    expect(role6.permissions.include?(permission1)).to be false
    expect(role6.permissions.include?(permission2)).to be true
  end
end
