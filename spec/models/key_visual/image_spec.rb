require 'spec_helper'

describe KeyVisual::Image, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :key_visual_node_image, cur_site: site }
  subject { create :key_visual_image, cur_site: site, cur_node: node }

  describe "#attributes" do
    it { expect(subject.becomes_with_route).not_to eq nil }
    it { expect(subject.dirname).not_to eq nil }
    it { expect(subject.basename).not_to eq nil }
    it { expect(subject.path).not_to eq nil }
    it { expect(subject.url).not_to eq nil }
    it { expect(subject.full_url).not_to eq nil }
    it { expect(subject.parent).to eq node }
    it { expect(subject.private_show_path).to eq Rails.application.routes.url_helpers.key_visual_image_path(site: subject.site, cid: subject.parent, id: subject) }
  end
end
