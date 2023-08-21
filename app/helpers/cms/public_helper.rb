module Cms::PublicHelper
  def paginate(*args, **options)
    if @cur_path.present?
      options[:paginator_class] = Cms::PublicHelper::Paginator
      super(*args, **options)
    else
      super
    end
  end

  def body_id(path)
    "body-" + path.to_s.sub(/\/$/, "/index").sub(/\.html$/, "").gsub(/[^\w-]+/, "-")
  end

  def body_class(path)
    prefix = "body-"
    nodes  = path.to_s.sub(/\/[^\/]+\.html$/, "").sub(/^\//, "").split("/")
    nodes  = nodes.map { |node| prefix = "#{prefix}-" + node.gsub(/[^\w-]+/, "-") }
    nodes.join(" ")
  end
end
