require 'spec_helper'
require Rails.root.join('lib/migrations/ss/20150807090501_fix_ss_files_state.rb')

RSpec.describe SS::Migration20150807090501, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:file1) { create :ss_file, site: site, user: user }
  let(:file2) { create :ss_file, site: site, user: user }
  let!(:cms_page) { create :cms_page, cur_site: site, file_ids: [file1.id] }
  let!(:facility_image) { create :facility_image, cur_site: site, image_id: file2.id }
  let!(:sitemap_page) { create :sitemap_page, cur_site: site }

  before do
    file1.set(state: 'public')
    file2.set(state: 'public')
    cms_page.set(state: 'closed')
    facility_image.set(state: 'closed')
    sitemap_page.set(state: 'closed')
  end

  it do
    described_class.new.change

    file1.reload
    file2.reload

    expect(file1.state).to eq 'closed'
    expect(file2.state).to eq 'closed'
  end
end
