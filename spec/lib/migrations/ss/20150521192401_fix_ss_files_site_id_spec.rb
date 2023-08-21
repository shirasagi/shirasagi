require 'spec_helper'
require Rails.root.join('lib/migrations/ss/20150521192401_fix_ss_files_site_id.rb')

RSpec.describe SS::Migration20150521192401, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:file1) { create :ss_file, site: site, user: user, state: 'public' }
  let(:file2) { create :ss_file, site: site, user: user, state: 'public' }
  let(:file3) { create :ss_file, site: site, user: user, state: 'public' }
  let!(:cms_page) { create :cms_page, cur_site: site, file_ids: [file1.id] }
  let!(:ads_banner) { create :ads_banner, cur_site: site, file_id: file2.id }
  let!(:facility_image) { create :facility_image, cur_site: site, image_id: file3.id }
  let!(:sitemap_page) { create :sitemap_page, cur_site: site }

  before do
    file1.update(site_id: nil)
    file2.update(site_id: nil)
    file3.update(site_id: nil)
  end

  it do
    described_class.new.change

    file1.reload
    file2.reload
    file3.reload

    expect(file1.site_id).to eq site.id
    expect(file2.site_id).to eq site.id
    expect(file3.site_id).to eq site.id
  end
end
