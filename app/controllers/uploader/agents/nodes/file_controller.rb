class Uploader::Agents::Nodes::FileController < ApplicationController
  include Cms::NodeFilter::View

  def index
    # アップローダー内にあるファイルは先に send_file で応答する為、この動的処理では応答しない。
    # see : Cms::PublicFilter #x_sendfile
    path = ::File.join(@cur_node.path, params[:filename].to_s)
    item = Uploader::File.file(path)
    raise SS::NotFoundError unless item
    head :ok
  end
end
