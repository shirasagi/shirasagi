require 'spec_helper'

RSpec.describe SS::ImageViewerHelper, type: :helper do
  let(:file) { Rails.root.join("spec", "fixtures", "ss", "file", "info.json") }
  let(:viewer) { helper.render_image_viewer "#viewer", tile_resources: file }

  describe 'image_viewer' do
    before do
      allow(controller).to receive(:javascript).and_return(true)
    end

    it 'render_image_viewer' do
      expect(viewer).to include('SS_ImageViewer.render(options)')
    end
  end
end
