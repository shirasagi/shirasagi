FactoryBot.define do
  factory :accessibility_tool, class: 'Cms::Part::Free' do
    name { unique_id.to_s }
    basename { "tool.part.html" }
    filename { "tool.part.html" }
    html do
      ::File.read("#{Rails.root}/db/seeds/demo/parts/tool.part.html")
    end
  end

  factory :accessibility_tool_custom, class: 'Cms::Part::Free' do
    name { unique_id.to_s }
    basename { "tool-#{unique_id}.part.html" }
    filename { "tool-#{unique_id}.part.html" }
    html do
      # material icon を用いてふりがなの on / off を表現
      <<~HTML
        <!-- アクセシビリティツール -->
        <div class="accessibility__tool-wrap">
          <nav class="accessibility__tool">
            <div class="accessibility__tool-list">
              <div data-tool="ss-kana" class="accessibility__kana">
                <span class="on-not-pressed">
                  <span class="material-icons-outlined" role="img" aria-hidden="true">toggle_off</span>
                  <span class="sr-only">ふりがなをつける</span>
                </span>
                <span class="on-pressed">
                  <span class="material-icons-outlined" role="img" aria-hidden="true">toggle_on</span>
                  <span class="sr-only">ふりがなをはずす</span>
                </span>
              </div>
              <div data-tool="ss-voice" class="accessibility__voice">
                <span class="material-icons-outlined" role="img" aria-hidden="true">voice_button</span>
                <span class="sr-only">読み上げる</span>
              </div>
              <div class="accessibility__theme">背景色
                <span data-tool="ss-theme">
                  <a href="#" class="white">白</a>
                  <a href="#" class="blue">青</a>
                  <a href="#" class="black">黒</a>
                </span>
              </div>
              <div class="accessibility__fontsize">文字サイズ
                <span data-tool="ss-small">小さく</span>
                <span data-tool="ss-medium">標準</span>
                <span data-tool="ss-large">大きく</span>
              </div>
            </div><!-- .accessibility__tool-list -->
          </nav><!-- .accessibility__tool -->
        </div><!--#tool .accessibility__tool-wrap -->
      HTML
    end
  end

  factory :accessibility_tool_compat1, class: 'Cms::Part::Free' do
    name { unique_id.to_s }
    basename { "tool-#{unique_id}.part.html" }
    filename { "tool-#{unique_id}.part.html" }
    html do
      # "id=" で機能を指定する形式
      <<~HTML
        <!-- アクセシビリティツール -->
        <div id="tool" class="accessibility__tool-wrap">
          <nav class="accessibility__tool">
            <div class="accessibility__tool-list">
              <div id="ss-kana" class="accessibility__kana">ふりがなをつける</div>
              <div id="ss-voice" class="accessibility__voice">読み上げる</div>
              <div id="theme" class="accessibility__theme">背景色
                <span id="ss-theme">
                  <a href="#" class="white">白</a>
                  <a href="#" class="blue">青</a>
                  <a href="#" class="black">黒</a>
                </span>
              </div>
              <div id="size" class="accessibility__fontsize">文字サイズ
                <span id="ss-small">小さく</span>
                <span id="ss-medium">標準</span>
                <span id="ss-large">大きく</span>
              </div>
            </div><!-- .accessibility__tool-list -->
          </nav><!-- .accessibility__tool -->
        </div><!--#tool .accessibility__tool-wrap -->
      HTML
    end
  end

  factory :accessibility_tool_compat2, class: 'Cms::Part::Free' do
    name { unique_id.to_s }
    basename { "tool-#{unique_id}.part.html" }
    filename { "tool-#{unique_id}.part.html" }
    html do
      # "data-tool=" で機能を指定する形式；ただし「ふりがなをつける」しかコーディングされていない。
      <<~HTML
        <!-- アクセシビリティツール -->
        <div class="accessibility__tool-wrap">
          <nav class="accessibility__tool">
            <div class="accessibility__tool-list">
              <div data-tool="ss-kana" class="accessibility__kana">ふりがなをつける</div>
              <div data-tool="ss-voice" class="accessibility__voice">読み上げる</div>
              <div class="accessibility__theme">背景色
                <span data-tool="ss-theme">
                  <a href="#" class="white">白</a>
                  <a href="#" class="blue">青</a>
                  <a href="#" class="black">黒</a>
                </span>
              </div>
              <div class="accessibility__fontsize">文字サイズ
                <span data-tool="ss-small">小さく</span>
                <span data-tool="ss-medium">標準</span>
                <span data-tool="ss-large">大きく</span>
              </div>
            </div><!-- .accessibility__tool-list -->
          </nav><!-- .accessibility__tool -->
        </div><!--#tool .accessibility__tool-wrap -->
      HTML
    end
  end
end
