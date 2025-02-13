require 'spec_helper'

# パーツが ajax 機能を正しくサポートしているかを網羅的に確認するテスト
# パーツが他のノードなどに依存する場合、本テストを正しく動作させるには factory で依存関係を正しく構成させる必要がある。
describe Cms::PublicController, type: :request, dbscope: :example do
  let!(:site) { cms_site }

  Cms::Part.plugins.map(&:path).each do |path|
    next if path == "cms/free"
    # opendata 機能は単体では動作せず、構成が大変
    next if path.start_with?("opendata/")
    # "ckan/reference" は opendata 機能と組み合わせて利用する必要があり、構成が大変
    next if path == "ckan/reference"

    context "ajax access to `#{path}`" do
      it do
        part = create(path.sub("/", "_part_").to_sym, cur_site: site)

        get part.full_url.sub(".html", ".json")
        expect(response.status).to eq 200
      end
    end
  end
end
