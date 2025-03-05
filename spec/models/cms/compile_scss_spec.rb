require 'spec_helper'

describe Cms, type: :model, dbscope: :example do
  describe ".compile_scss" do
    let!(:site) { cms_site }
    let!(:node) { create :uploader_node_file, cur_site: site }
    let(:scss_source) do
      <<~SCSS
        @import "compass-mixins/lib/compass";
        @import "compass-mixins/lib/animate";

        .hello {
          display: none;
        }
      SCSS
    end

    it do
      FileUtils.mkdir_p(node.path)
      source_path = "#{node.path}/style.scss"
      ::File.write(source_path, scss_source)

      output_path = "#{node.path}/style.css"
      Cms.compile_scss(source_path, output_path, basedir: site.path)

      compiled = ::File.read(output_path)
      expect(compiled).to be_present
      expect(compiled).to include('.hello', 'sourceMappingURL')
    end
  end
end
