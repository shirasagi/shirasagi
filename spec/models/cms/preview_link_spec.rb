require 'spec_helper'

describe Cms::PreviewLink, type: :model, dbscope: :example do
  let!(:site) { cms_site }
  let!(:subsite1) do
    create(:cms_site_subdir, domains: site.domains, parent: site, subdir: "sub1", group_ids: site.group_ids)
  end
  let!(:subsite2) do
    create(:cms_site_subdir, domains: site.domains, parent: site, subdir: "sub2", group_ids: site.group_ids)
  end

  shared_examples "expand preview link" do
    it do
      item = described_class.new(cur_site, preview_url, preview_path, url)
      expect(item.expanded).to eq expanded
      expect(item.external?).to eq external
    end
  end

  context "href ignore path" do
    context "in root site" do
      let(:cur_site) { site }
      let(:preview_url) { cms_preview_path(site: cur_site) }

      context "in top page" do
        let(:preview_path) { nil }

        context "assets" do
          let(:url) { "/assets/cms/public.css" }
          let(:expanded) { url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "assets-dev" do
          let(:url) { "/assets-dev/ss/style.css" }
          let(:expanded) { url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "#" do
          let(:url) { "#" }
          let(:expanded) { url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end
      end
    end
  end

  context "href relative path" do
    context "in root site" do
      let(:cur_site) { site }
      let(:preview_url) { cms_preview_path(site: cur_site) }

      context "in top page" do
        let(:preview_path) { nil }

        context "/" do
          let(:url) { "/" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/index.html" do
          let(:url) { "/index.html" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/node/" do
          let(:url) { "/node/" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/node/page.html" do
          let(:url) { "/node/page.html" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./" do
          let(:url) { "./" }
          let(:expanded) { cms_preview_path(site: cur_site) + site.url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./page.html" do
          let(:url) { "./page.html" }
          let(:expanded) { cms_preview_path(site: site, path: "page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../" do
          let(:url) { "../" }
          let(:expanded) { cms_preview_path(site: cur_site) + site.url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../../" do
          let(:url) { "../../" }
          let(:expanded) { cms_preview_path(site: cur_site) + site.url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "page.html" do
          let(:url) { "page.html" }
          let(:expanded) { cms_preview_path(site: site, path: "page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end
      end

      context "in node" do
        let(:preview_path) { "node" }

        context "/" do
          let(:url) { "/" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/index.html" do
          let(:url) { "/index.html" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/node/" do
          let(:url) { "/node/" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/node/page.html" do
          let(:url) { "/node/page.html" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./" do
          let(:url) { "./" }
          let(:expanded) { cms_preview_path(site: site, path: "node") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./page.html" do
          let(:url) { "./page.html" }
          let(:expanded) { cms_preview_path(site: site, path: "node/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../" do
          let(:url) { "../" }
          let(:expanded) { cms_preview_path(site: cur_site) + site.url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../../" do
          let(:url) { "../../" }
          let(:expanded) { cms_preview_path(site: cur_site) + site.url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "page.html" do
          let(:url) { "page.html" }
          let(:expanded) { cms_preview_path(site: site, path: "node/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end
      end

      context "in node/" do
        let(:preview_path) { "node/" }

        context "/" do
          let(:url) { "/" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/index.html" do
          let(:url) { "/index.html" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/node/" do
          let(:url) { "/node/" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/node/page.html" do
          let(:url) { "/node/page.html" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./" do
          let(:url) { "./" }
          let(:expanded) { cms_preview_path(site: site, path: "node") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./page.html" do
          let(:url) { "./page.html" }
          let(:expanded) { cms_preview_path(site: site, path: "node/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../" do
          let(:url) { "../" }
          let(:expanded) { cms_preview_path(site: cur_site) + site.url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../../" do
          let(:url) { "../../" }
          let(:expanded) { cms_preview_path(site: cur_site) + site.url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "page.html" do
          let(:url) { "page.html" }
          let(:expanded) { cms_preview_path(site: site, path: "node/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end
      end

      context "in node/index.html" do
        let(:preview_path) { "node/index.html" }

        context "/" do
          let(:url) { "/" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/index.html" do
          let(:url) { "/index.html" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/node/" do
          let(:url) { "/node/" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/node/page.html" do
          let(:url) { "/node/page.html" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./" do
          let(:url) { "./" }
          let(:expanded) { cms_preview_path(site: site, path: "node") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./page.html" do
          let(:url) { "./page.html" }
          let(:expanded) { cms_preview_path(site: site, path: "node/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../" do
          let(:url) { "../" }
          let(:expanded) { cms_preview_path(site: cur_site) + site.url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../../" do
          let(:url) { "../../" }
          let(:expanded) { cms_preview_path(site: cur_site) + site.url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "page.html" do
          let(:url) { "page.html" }
          let(:expanded) { cms_preview_path(site: site, path: "node/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end
      end

      context "in node1/node2/node3/" do
        let(:preview_path) { "node1/node2/node3/" }

        context "/" do
          let(:url) { "/" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/index.html" do
          let(:url) { "/index.html" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/node/" do
          let(:url) { "/node/" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/node/page.html" do
          let(:url) { "/node/page.html" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./" do
          let(:url) { "./" }
          let(:expanded) { cms_preview_path(site: site, path: "node1/node2/node3") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./page.html" do
          let(:url) { "./page.html" }
          let(:expanded) { cms_preview_path(site: site, path: "node1/node2/node3/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../" do
          let(:url) { "../" }
          let(:expanded) { cms_preview_path(site: site, path: "node1/node2") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../../" do
          let(:url) { "../../" }
          let(:expanded) { cms_preview_path(site: site, path: "node1") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "page.html" do
          let(:url) { "page.html" }
          let(:expanded) { cms_preview_path(site: site, path: "node1/node2/node3/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end
      end
    end

    context "in subsite1" do
      let(:cur_site) { subsite1 }
      let(:preview_url) { cms_preview_path(site: cur_site) }

      context "in top page" do
        let(:preview_path) { nil }

        context "/" do
          let(:url) { "/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "/index.html" do
          let(:url) { "/index.html" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "/node/" do
          let(:url) { "/node/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "/node/page.html" do
          let(:url) { "/node/page.html" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "/sub1/" do
          let(:url) { "/sub1/" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/sub1/index.html" do
          let(:url) { "/sub1/index.html" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/index.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/sub1/node/" do
          let(:url) { "/sub1/node/" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/node/") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/sub1/node/page.html" do
          let(:url) { "/sub1/node/page.html" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/node/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./" do
          let(:url) { "./" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./page.html" do
          let(:url) { "./page.html" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../" do
          let(:url) { "../" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "../../" do
          let(:url) { "../../" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "page.html" do
          let(:url) { "page.html" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end
      end

      context "in /node/" do
        let(:preview_path) { "node/" }

        context "/" do
          let(:url) { "/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "/index.html" do
          let(:url) { "/index.html" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "/node/" do
          let(:url) { "/node/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "/node/page.html" do
          let(:url) { "/node/page.html" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "/sub1/" do
          let(:url) { "/sub1/" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/sub1/index.html" do
          let(:url) { "/sub1/index.html" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/index.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/sub1/node/" do
          let(:url) { "/sub1/node/" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/node/") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/sub1/node/page.html" do
          let(:url) { "/sub1/node/page.html" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/node/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./" do
          let(:url) { "./" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/node") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "./page.html" do
          let(:url) { "./page.html" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/node/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../" do
          let(:url) { "/sub1/" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "../../" do
          let(:url) { "../../" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "page.html" do
          let(:url) { "page.html" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/node/page.html") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end
      end
    end
  end

  context "href relative path (edge case)" do
    context "in root site" do
      let(:cur_site) { site }
      let(:preview_url) { cms_preview_path(site: cur_site) }

      context "in top page" do
        let(:preview_path) { nil }

        context "/search/?s%5Bkeyword%5D=" do
          let(:url) { "/search/?s%5Bkeyword%5D=" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "/あいうえお" do
          let(:url) { "/あいうえお" }
          let(:expanded) { cms_preview_path(site: cur_site) + url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end
      end
    end
  end

  context "href external full url" do
    context "in root site" do
      let(:cur_site) { site }
      let(:preview_url) { cms_preview_path(site: cur_site) }

      context "in top page" do
        let(:preview_path) { nil }

        context "href http://sample.examle.jp" do
          let(:url) { "http://sample.examle.jp" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://sample.examle.jp/" do
          let(:url) { "http://sample.examle.jp/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://sample.examle.jp/docs/" do
          let(:url) { "http://sample.examle.jp/docs/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href https://sample.examle.jp" do
          let(:url) { "https://sample.examle.jp" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href https://sample.examle.jp/" do
          let(:url) { "https://sample.examle.jp/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href https://sample.examle.jp/docs/" do
          let(:url) { "https://sample.examle.jp/docs/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end
      end
    end
  end

  context "href cms sites full url" do
    context "in root site" do
      let(:cur_site) { site }
      let(:preview_url) { cms_preview_path(site: cur_site) }

      context "in top page" do
        let(:preview_path) { nil }

        context "href http://{domain}" do
          let(:url) { "http://#{site.domain}" }
          let(:expanded) { cms_preview_path(site: cur_site) + site.url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/" do
          let(:url) { "http://#{site.domain}/" }
          let(:expanded) { cms_preview_path(site: cur_site) + site.url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/node/" do
          let(:url) { "http://#{site.domain}/node/" }
          let(:expanded) { cms_preview_path(site: site, path: "node/") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub1" do
          let(:url) { "http://#{site.domain}/sub1" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub1/" do
          let(:url) { "http://#{site.domain}/sub1/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub2/node/" do
          let(:url) { "http://#{site.domain}/sub2/node/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub2" do
          let(:url) { "http://#{site.domain}/sub2" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub2/" do
          let(:url) { "http://#{site.domain}/sub2/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub2/node/" do
          let(:url) { "http://#{site.domain}/sub2/node/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end
      end
    end

    context "in subsite1" do
      let(:cur_site) { subsite1 }
      let(:preview_url) { cms_preview_path(site: cur_site) }

      context "in top page" do
        let(:preview_path) { nil }

        context "href http://{domain}" do
          let(:url) { "http://#{site.domain}" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/" do
          let(:url) { "http://#{site.domain}/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/node/" do
          let(:url) { "http://#{site.domain}/node/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub1" do
          let(:url) { "http://#{site.domain}/sub1" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub1/" do
          let(:url) { "http://#{site.domain}/sub1/" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub1/node/" do
          let(:url) { "http://#{site.domain}/sub1/node/" }
          let(:expanded) { cms_preview_path(site: cur_site, path: "sub1/node/") }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub2/node/" do
          let(:url) { "http://#{site.domain}/sub2/node/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub2" do
          let(:url) { "http://#{site.domain}/sub2" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub2/" do
          let(:url) { "http://#{site.domain}/sub2/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end

        context "href http://{domain}/sub2/node/" do
          let(:url) { "http://#{site.domain}/sub2/node/" }
          let(:expanded) { url }
          let(:external) { true }

          it_behaves_like "expand preview link"
        end
      end
    end
  end

  context "href not supported scheme" do
    context "in root site" do
      let(:cur_site) { site }
      let(:preview_url) { cms_preview_path(site: cur_site) }

      context "in top page" do
        let(:preview_path) { nil }

        context "mailto:mail@sample.example.com" do
          let(:url) { "mailto:mail@sample.example.com" }
          let(:expanded) { url }
          let(:external) { false }

          it_behaves_like "expand preview link"
        end
      end
    end
  end
end
