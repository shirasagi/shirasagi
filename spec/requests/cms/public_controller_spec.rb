require 'spec_helper'

describe Cms::PublicController, type: :request, dbscope: :example do
  let!(:site) { cms_site }

  it do
    components = %w(docs)
    components += Array.new(site.path.count("/") + 1) { ".." }
    components << Rails.root.to_s
    components << "README.md"
    path = File.join(*components)
    get "#{site.full_url}#{path}"
    expect(response.status).to eq 404
  end
end
