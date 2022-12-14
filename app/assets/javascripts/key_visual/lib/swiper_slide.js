//= require swiper/dist/js/swiper.js
//= require_self

this.KeyVisual_SwiperSlide = (function () {
  function KeyVisual_SwiperSlide(el, options) {
    this.el = document.querySelector(el);
    this.options = options;

    this.render();
  }

  KeyVisual_SwiperSlide.instances = {};

  KeyVisual_SwiperSlide.prototype.render = function() {
    var self = this;

    var thumbnailSlider = null;
    if (self.options.thumbnail === "show") {
      thumbnailSlider = self.createThumbnailSlider();
    }

    var mainSliderOption = {
      loop: true,
      speed: self.options.speed
    }

    if (self.options.autoplay === "enabled" || self.options.autoplay === "started") {
      mainSliderOption.autoplay = {
        delay: self.options.pause,
        disableOnInteraction: false,
      };
    }

    if (self.options.space && self.options.space > 0) {
      mainSliderOption.spaceBetween = self.options.space;
    }

    if (self.options.navigation === "show") {
      var nextEl = self.el.querySelector(".ss-swiper-slide-button-next");
      var prevEl = self.el.querySelector(".ss-swiper-slide-button-prev");
      if (nextEl || prevEl) {
        mainSliderOption.navigation = {};
        if (nextEl) {
          nextEl.classList.remove("hide")
          mainSliderOption.navigation.nextEl = nextEl;
        }
        if (prevEl) {
          prevEl.classList.remove("hide")
          mainSliderOption.navigation.prevEl = prevEl;
        }
      }
    }

    if (self.options.pagination_style === "disc" || self.options.pagination_style === "number") {
      var paginationEl = self.el.querySelector(".ss-swiper-slide-pagination");
      if (paginationEl) {
        paginationEl.classList.remove("hide")
        mainSliderOption.pagination = {
          el: paginationEl,
          clickable: true
        };
      }
    }

    if (self.options.pagination_style === "number") {
      mainSliderOption.pagination.renderBullet = function (index, className) {
        return '<span class="' + className + ' ss-swiper-slide-pagination-bullet-number">' + (index + 1) + '</span>';
      };
    }

    if (self.options.thumbnail === "show" && thumbnailSlider) {
      mainSliderOption.thumbs = { swiper: thumbnailSlider };
    }

    self.swiper = new Swiper(self.el.querySelector(".ss-swiper-slide-main"), mainSliderOption);
    if (self.options.test) {
      self.swiper.on("transitionEnd", function () {
        self.triggerEvent("transitionEnd");
      });
    }

    if (self.options.autoplay === "enabled" || self.options.autoplay === "started") {
      var playButton = self.el.querySelector(".ss-swiper-slide-play");
      if (playButton) {
        playButton.addEventListener("click", function() {
          self.swiper.autoplay.start();
        });
      }
      var stopButton = self.el.querySelector(".ss-swiper-slide-stop");
      if (stopButton) {
        stopButton.addEventListener("click", function () {
          self.swiper.autoplay.stop();
        });
      }
      self.swiper.on("autoplayStart", function() {
        playButton.setAttribute("aria-pressed", true);
        stopButton.setAttribute("aria-pressed", false);
        if (self.options.test) {
          self.triggerEvent("autoplayStart");
        }
      });
      self.swiper.on("autoplayStop", function() {
        playButton.setAttribute("aria-pressed", false);
        stopButton.setAttribute("aria-pressed", true);
        if (self.options.test) {
          self.triggerEvent("autoplayStop");
        }
      });
    }
    if (self.options.autoplay === "enabled") {
      self.swiper.autoplay.stop();
    }
  };

  KeyVisual_SwiperSlide.prototype.createThumbnailSlider = function() {
    var self = this;

    var thumbnailSliderOption = {
      loop: true,
      slidesPerView: self.options.thumbnail_count,
      freeMode: true,
      watchSlidesVisibility: true,
      watchSlidesProgress: true
    };

    if (self.options.space) {
      thumbnailSliderOption.spaceBetween = self.options.space / self.options.thumbnail_count;
    }

    return new Swiper(self.el.querySelector(".ss-swiper-slide-thumbnail"), thumbnailSliderOption);
  };

  KeyVisual_SwiperSlide.prototype.triggerEvent = function(eventName) {
    var self = this;

    var ev = document.createEvent("Event");
    ev.initEvent(eventName, true, true);
    self.el.dispatchEvent(ev);
  };

  return KeyVisual_SwiperSlide;
})();
