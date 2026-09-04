import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    SS.justOnce(this.element, "js-color", () => this.#render());

    this.element.addEventListener("ss:colorchange", (ev) => {
      const rgb = ev.detail?.rgb;
      if (rgb) {
        $(this.element).minicolors("value", rgb);
      }
    })
  }

  disconnect() {
  }

  #render() {
    const $el = $(this.element);
    if ($el.data("swatches")) {
      this.#initializeWithSwatches();
    } else {
      $el.minicolors();
    }

    if ($el.data('clear')) {
      this.#addClearBtn();
    }
    if ($el.data('random')) {
      this.#addRandomBtn();
    }

    $el.attr("aria-busy", false).trigger("ss:colorPickerReady");
  }

  #initializeWithSwatches() {
    const $el = $(this.element);
    $el.minicolors({ swatches: DEFAULT_SWATCHES });

    const $warp = $el.closest(".minicolors");
    const $slider = $warp.find('.minicolors-slider');
    const $swatches = $warp.find('ul.minicolors-swatches');
    const $panel = $warp.find(".minicolors-panel");

    $panel.prepend($swatches);
    var top = $warp.find('li.minicolors-swatch.minicolors-sprite').outerHeight(true) * 2
      + $swatches.outerHeight(true)
      + parseInt($slider.css('top'));

    $slider.css('top', top.toString() + 'px');
  };

  #addClearBtn() {
    const $el = $(this.element);
    const $clearBtn = $("<input />", { type: 'button', class: 'btn', value: i18next.t('ss.buttons.clear') });
    $el.after($clearBtn).after(' ');
    $clearBtn.on("click", function () {
      $el.minicolors('value', { color: 'transparent' });
    });
  };

  #addRandomBtn() {
    const $el = $(this.element);
    const randomColor = $el.data('random').split(' ');
    let randomIndex = 0;
    const $randomGenBtn = $("<input />", { type: 'button', class: 'btn', value: i18next.t('ss.buttons.random_gen') });
    $el.after($randomGenBtn).after(' ');
    $randomGenBtn.on("click", function () {
      var nextColor = randomColor[randomIndex];
      randomIndex++;
      if (randomIndex >= randomColor.length) {
        randomIndex = 0;
      }
      $el.minicolors('value', { color: nextColor });
    });
  };
}

