require 'spec_helper'

describe Cms, type: :model, dbscope: :example do
  describe ".compile_scss" do
    let(:scss_source) do
      <<~SCSS
        .hello {
          display: none;
        }
      SCSS
    end

    it do
      load_paths = Rails.application.config.assets.paths.dup
      compiled = Cms.compile_scss(scss_source, load_paths: load_paths, filename: "#{Rails.root}/css/style.scss")
      expect(compiled).to be_present
    end
  end
end
