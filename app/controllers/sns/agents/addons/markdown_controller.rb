class Sns::Agents::Addons::MarkdownController < ApplicationController
  include Sns::BaseFilter

  def preview
    render plain: SS::Addon::Markdown.text_to_html(params[:text])
  end
end
