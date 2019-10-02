module ExtractImgSrcFilter
  def extract_img_src(html)
    ::SS::Html.extract_img_src(html)
  end
end

Liquid::Template.register_filter(ExtractImgSrcFilter)
