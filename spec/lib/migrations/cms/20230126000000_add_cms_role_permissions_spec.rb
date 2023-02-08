require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20230126000000_add_cms_role_permissions.rb")

RSpec.describe SS::Migration20230126000000, dbscope: :example do
  let!(:role1) { create :cms_role }
  let!(:role2) { create :cms_role_admin }
  let!(:role3) do
    role = create :cms_role_admin
    permissions = role.permissions.select do |name|
      result = nil
      result ||= false if name.starts_with?('close_')
      result ||= false if name.start_with?('release_') && rand(10) == 0
      result || true
    end
    role.set(permissions: permissions)
  end
  let!(:targets) do
    %w(
      release_other_article_pages
      release_private_article_pages

      release_other_cms_pages
      release_private_cms_pages

      release_other_event_pages
      release_private_event_pages

      release_other_faq_pages
      release_private_faq_pages

      release_other_member_blogs
      release_private_member_blogs
      release_other_member_photos
      release_private_member_photos

      release_other_opendata_datasets
      release_private_opendata_datasets
      release_member_opendata_datasets

      release_other_opendata_apps
      release_private_opendata_apps
      release_member_opendata_apps

      release_other_opendata_ideas
      release_private_opendata_ideas
      release_member_opendata_ideas

      release_other_sitemap_pages
      release_private_sitemap_pages
    ).compact
  end

  before do
    described_class.new.change
  end

  it do
    [role1, role2, role3].each do |item|
      item.reload
      targets.each do |src|
        dst = src.sub(/\Arelease_/, 'close_')
        exists = item.permissions.include?(src)
        expect(item.permissions.include?(dst)).to eq exists
      end
    end
  end
end
