class SS::LiquidPartDrop < Liquid::Drop
  def initialize(site)
    @site = site
  end

  def key?(filename)
    Cms::Part.site(@site).and_public.where(filename: normalize_filename(filename)).present? || super
  end

  def [](method_or_key)
    find_part(method_or_key) || super
  end

  private

  def find_part(filename)
    part = Cms::Part.site(@site).and_public.where(filename: normalize_filename(filename)).first
    part = part.becomes_with_route if part
    part
  end

  def normalize_filename(filename)
    if !filename.include?(".")
      filename = "#{filename}.part.html"
    end

    filename
  end
end
