require 'spec_helper'

describe 'ss_nginx_config', dbscope: :example do
  let!(:site1) { create :ss_site, name: 'site1', host: 'www1', domains: %w(site1.example.jp) }
  let!(:site2) { create :ss_site, name: 'site2', host: 'www2', domains: %w(site2.example.jp:3000) }
  let!(:group1) { create :ss_group, name: 'group1', domains: %w(g1.example.jp) }
  let!(:group2) { create :ss_group, name: 'group2', domains: %w(g2.example.jp:3000) }
  let(:file) { "#{Rails.root}/tmp/nginx.conf" }
  let(:item) { SS::Nginx::Config.new }

  before do
    item.virtual_conf = file
    item.write
  end

  after do
    ::FileUtils.rm(file) if ::File.exist?(file)
  end

  it do
    conf = ::File.read(file)

    expect(conf).to include("server_name #{site1.domain};")
    expect(conf).to include("root #{site1.root_path};")

    expect(conf).to include("server_name #{site2.domain.sub(/:.*/, '')};")
    expect(conf).to include("root #{site2.root_path};")
    expect(conf).to include("listen 3000;")

    expect(conf).to include("server_name #{group1.domain};")
    expect(conf).to include("root #{Rails.root}/public;")

    expect(conf).to include("server_name #{group2.domain.sub(/:.*/, '')};")
    expect(conf).to include("root #{Rails.root}/public;")
    expect(conf).to include("listen 3000;")
  end
end
