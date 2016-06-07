module Member::MypageHelper
  def render_mypage_navi(opts = {})
    @mypage_node = Member::Node::Mypage.site(@cur_site).first
    current_node = opts[:current_node]

    h = []
    h << %(<nav id="mypage-tabs">)
    @mypage_node.children.each do |c|
      current = (current_node.url == c.url) ? " current" : ""
      h << %(<a class="#{c.basename}#{current}" href="#{c.url}">#{c.name}</a>)
    end
    h << %(</nav>)
    h.join
  end

  def required_label
    content_tag('span', t('views.required_field'), class: :required)
  end

  # def example(key, html_wrap = true)
  #   modelnames = @model.ancestors.select { |x| x.respond_to?(:model_name) }
  #   msg = ""
  #   modelnames.each do |modelname|
  #     msg = I18n.t("examples.#{modelname.model_name.i18n_key}.#{key}", default: "")
  #     break if msg.present?
  #   end
  #   return msg if msg.blank? || !html_wrap
  #   msg = msg.join(", ") if msg.respond_to?(:join)
  #   %(<span class="example">#{msg}</span>).html_safe
  # end

  def remarks(key, html_wrap = true, options = {})
    modelnames = @model.ancestors.select { |x| x.respond_to?(:model_name) }
    msg = ""
    modelnames.each do |modelname|
      msg = I18n.t("remarks.#{modelname.model_name.i18n_key}.#{key}", default: "")
      break if msg.present?
    end
    return msg if msg.blank? || !html_wrap
    msg = [msg].flatten if msg.class != Array
    msg = msg.map { |d| I18n.interpolate(d, options) }
    list = msg.map {|d| "<li>" + d.to_s.gsub(/\r\n|\n/, "<br />") + "<br /></li>"}

    h = []
    h << %(<div class="remarks">)
    h << %(<ul>)
    h << list
    h << %(</ul>)
    h << %(</div>)
    h.join("\n").html_safe
  end
end
