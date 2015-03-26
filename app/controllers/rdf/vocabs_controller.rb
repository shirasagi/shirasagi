class Rdf::VocabsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Rdf::Vocab

  navi_view "cms/main/navi"

  before_action :set_extra_crumbs, only: [:show, :edit, :update, :delete, :destroy]

  private
    def fix_params
      { cur_site: @cur_site }
    end

    def set_crumbs
      @crumbs << [:"rdf.vocabs", action: :index]
    end

    def set_extra_crumbs
      set_item
      @crumbs << [@item.label, action: :show, id: @item] if @item.present?
    end
end
