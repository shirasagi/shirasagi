class Gws::Apis::CkeConfigController < ApplicationController
  include Gws::BaseFilter

  protect_from_forgery except: :index

  def index
    # テナントごとに・サイトごとに CKEditor のツールバーを変更した場合、ここをカスタマイズしてください。
    render template: "sys/apis/cke_config/index"
  end
end
