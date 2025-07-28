class Kana::DiagnosticsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Kana::Dictionary

  navi_view "kana/main/conf_navi"
  menu_view nil

  before_action :lazy_load_mecab

  private

  def lazy_load_mecab
    require "MeCab"
  end

  def set_crumbs
    @crumbs << [t("kana.diagnostic"), url_for(action: :show)]
  end

  def set_item
  end

  public

  def show
    raise "403" unless @model.allowed?(:build, @cur_user, site: @cur_site)
    render
  end

  def update
    raise "403" unless @model.allowed?(:build, @cur_user, site: @cur_site)

    @text = params.require(:item).permit(:text)[:text]
    if @text.blank?
      render template: "show"
      return
    end

    Kana::Dictionary.pull(@cur_site.id) do |userdic|
      mecab_param = '--node-format=%ps,%pe,%m,%H\n --unk-format='
      if userdic.present?
        mecab_param = "-u #{userdic} " + mecab_param
      end
      mecab = MeCab::Tagger.new(mecab_param)
      @result = mecab.parse(@text)
    end

    render template: "show"
  end
end
