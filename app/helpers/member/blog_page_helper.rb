module Member::BlogPageHelper
  def render_blog_list(&block)
    cur_item = @cur_part || @cur_node
    cur_item.cur_date = @cur_date

    h = []
    h << cur_item.upper_html.html_safe if cur_item.upper_html.present?
    if block_given?
      h << capture(&block)
    else
      @items.each do |item|
        if cur_item.loop_html.present?
          ih = cur_item.render_loop_html(item)
        else
          ih = []
          ih << '<article class="blog thumb">'
          ih << '  <img class="thumb" src="#{img.src}">'
          ih << '  <header><h2><a href="#{url}">#{name}</a></h2></header>'
          ih << '  <div class="description">#{description}</div>'
          ih << '</article>'
          ih = cur_item.render_loop_html(item, html: ih.join("\n"))
        end
        h << ih.gsub('#{current}', current_url?(item.url).to_s)
      end
    end
    h << cur_item.lower_html.html_safe if cur_item.lower_html.present?

    h.join.html_safe
  end

  def render_blog_template(name, opts = {})
    case name.to_sym
    when :genres
      render_genres(opts[:node]) rescue nil
    when :thumb
      render_thumb(opts[:node]) rescue nil
    else
      nil
    end
  end

  def render_genres(node)
    return "" unless node.genres.present?

    h = []
    h << %(<div class="member-blog-pages genres">)
    h << %(<h2>記事ジャンル</h2>)
    h << %(<ul>)

    pages = node.pages.and_public
    node.genres.each do |genre|
      count = pages.in(genres: genre).count
      next unless count > 0
      h << %(<li><a href="#{node.url}?g=#{genre}">#{genre}(#{count})</a></li>)
    end

    h << %(</ul>)
    h << %(</div>)
    h.join
  end

  def render_thumb(node)
    h = []
    h << %(<article class="member-blog-pages thumb">)
    h << %(<img src="#{node.thumb_url}" class="thumb" />)
    h << %(<header><h2><a href="#{node.url}">#{node.name}</a></h2></header>)
    h << %(<div class="contributor">#{node.contributor}</div>)
    h << %(<div class="description">#{node.description}</div>)
    h << %(</article>)
    h.join
  end
end
