require 'spec_helper'

describe "gws_board_topics", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_board_topics_path site }
end
