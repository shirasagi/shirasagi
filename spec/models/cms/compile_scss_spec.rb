require 'spec_helper'

describe Cms, type: :model, dbscope: :example do
  describe ".compile_scss" do
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
      filename = "#{Rails.root}/public/sites/#{"test".chars.join("/")}/_/css/style.scss"
      load_paths = Rails.application.config.assets.paths.dup
      compiled = Cms.compile_scss(scss_source, load_paths: load_paths, filename: filename)
      expect(compiled).to be_present
      expect(compiled).to include('.hello', 'sourceMappingURL')
    end
  end
end
