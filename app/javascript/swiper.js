import "./swiper.scss"
import { register } from 'swiper/element/bundle';
register()

class KeyVisual_SwiperSlide {
  el = undefined;
  options = undefined;
  swiperContainer = undefined;

  constructor(el, options) {
    this.el = document.querySelector(el);
    this.options = options;
    this.swiperContainer = this.el.querySelector(".ss-swiper-slide-container");
    if (!this.swiperContainer) {
      return;
    }

    SS.justOnce(this.el, "swiperSlide", () => this.#render());
  }

  #render() {
    if (!this.options) {
      this.swiperContainer.initialize();
      return this;
    }

    if (this.options.navigation) {
      this.options.navigation.nextEl = this.el.querySelector(this.options.navigation.nextEl);
      this.options.navigation.prevEl = this.el.querySelector(this.options.navigation.prevEl);
    }
    if (this.options.pagination) {
      if (this.options.pagination.el) {
        this.options.pagination.el = this.el.querySelector(this.options.pagination.el);
      }
      if (this.options.pagination.type === "number") {
        this.options.pagination.type = "bullets";
        this.options.pagination.renderBullet = (index, className) => {
          const slideNo = index + 1;
          let ariaLabel = `Go to slide ${slideNo}`;

          if (this.options.a11y && this.options.a11y.paginationBulletMessage) {
            ariaLabel = this.options.a11y.paginationBulletMessage.replace("{{index}}", `${slideNo}`);
          }
          return `<span class="${className} ss-swiper-slide-pagination-bullet-number" tabindex="0" role="button" aria-label="${ariaLabel}">${slideNo}</span>`;
        };
      }
    }
    if (this.options.thumbs) {
      this.options.thumbs.swiper = this.el.querySelector(this.options.thumbs.swiper).swiper;
    }
    if (this.options.autoplay) {
      const playButton = this.el.querySelector(".ss-swiper-slide-play");
      if (playButton) {
        playButton.addEventListener("click", () => {
          this.swiperContainer.swiper.autoplay.start();
        });
      }
      const stopButton = this.el.querySelector(".ss-swiper-slide-stop");
      if (stopButton) {
        stopButton.addEventListener("click", () => {
          this.swiperContainer.swiper.autoplay.stop();
        });
      }

      const updateButtons = (ev) => {
        if (playButton) {
          playButton.setAttribute("aria-pressed", ev.detail[0].autoplay.running);
        }
        if (stopButton) {
          stopButton.setAttribute("aria-pressed", !ev.detail[0].autoplay.running);
        }
      };
      this.swiperContainer.addEventListener("swiperautoplaystart", updateButtons);
      this.swiperContainer.addEventListener("swiperautoplaystop", updateButtons);
    }

    Object.assign(this.swiperContainer, this.options);
    this.swiperContainer.initialize();
    return this;
  }
}

window.ss ||= {};
window.ss.KeyVisual_SwiperSlide = KeyVisual_SwiperSlide;
