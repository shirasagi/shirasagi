module Member::BlogPageHelper
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
    h << %(<h2>#{I18n.t('member.view.blog.genres')}</h2>)
    h << %(<ul>)

    pages = node.pages.and_public
    node.genres.each do |genre|
      count = pages.in(genres: genre).count
      next unless count > 0
      genre_name = sanitize genre
      h << %(<li><a href="#{node.url}?g=#{genre_name}">#{genre_name}(#{count})</a></li>)
    end

    h << %(</ul>)
    h << %(</div>)
    h.join
  end

  def render_thumb(node)
    h = []
    h << %(<article class="member-blog-pages thumb">)
    h << %(<img src="#{node.thumb_url}" class="thumb" />)
    h << %(<header><h2><a href="#{node.url}">#{sanitize node.name}</a></h2></header>)
    h << %(<div class="contributor">#{sanitize node.contributor}</div>)
    h << %(<div class="description">#{sanitize node.description}</div>)
    h << %(</article>)
    h.join
  end
end
