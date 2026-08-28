document.addEventListener("DOMContentLoaded", function () {
  const sliders = document.querySelectorAll(".article-slider");

  if (sliders.length === 0) {
    return;
  }

  sliders.forEach(function (slider) {
    const container = slider.querySelector("swiper-container");

    if (!container) {
      return;
    }

    Object.assign(container, {
      loop: true,
      slidesPerView: 1,
      spaceBetween: 20,

      pagination: {
        el: slider.querySelector(".article-slider__pagination"),
        clickable: true,
      },

      navigation: {
        nextEl: slider.querySelector(".article-slider__next"),
        prevEl: slider.querySelector(".article-slider__prev"),
      },
    });

    container.initialize();
  });
});
