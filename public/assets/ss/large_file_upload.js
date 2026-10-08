globalThis.SS_Large_File_Upload = (function() {

  function getFileWithoutExtension(filename) {
    return filename.replace(/\.[^/.]+$/, "");
  }

  const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

  async function fetchWithRetry({ authenticityToken, url, formData, numRetry }) {
    for (let i = 0; i < numRetry; i++) {
      try {
        return await fetch(url, {
          method: "POST",
          headers: { "X-CSRF-Token": authenticityToken },
          body: formData,
        })
      } catch (err) {
        if (i === numRetry - 1) throw err;
        await sleep(10_000);
      }
    }
  }

  const partition = (array, predicator) =>
    array.reduce(
      ([left, right], value) =>
        predicator(value) ? [[...left, value], right] : [left, [...right, value]],
      [[], []]
    )

  class SS_Large_File_Upload {
    constructor($el, { initUrl, finalizeUrl, createUrl }) {
      this.$el = $el;
      this.initUrl = initUrl;
      this.finalizeUrl = finalizeUrl;
      this.createUrl = createUrl;

      this.#render();
    }

    _authenticityToken = undefined

    get #authenticityToken() {
      if (!this._authenticityToken) {
        this._authenticityToken = $('meta[name="csrf-token"]').attr('content');
      }
      return this._authenticityToken;
    }

    #render() {
      this.$el.on('click', () => {
        $(".main-box .import-button").prop("disabled", true);
        $('.progress .progress-info').empty();
        this.#appendLoadingWrapper();
        this.#importFiles();
      });

      $(".main-box #file-picker").on("change", () => {
        $(".main-box .import-button").prop("disabled", false);
      });
    }

    async #importFiles() {
      const initParams = new FormData();
      const allFiles = Array.from(this.$el.prev().prop("files"), (file) => {
        return {"id": crypto.randomUUID(), "file": file}
      });
      this.#setInitParams(allFiles, initParams);

      const initResponse = await fetch(this.initUrl, {
        method: "POST",
        headers: { "X-CSRF-Token": this.#authenticityToken },
        body: initParams,
      });

      const initResult = await initResponse.json();
      const allowedFiles = initResult.files;
      if (!allowedFiles || allowedFiles.length === 0) {
        this.#noUploadableFile(allFiles);
        return
      }

      this.#appendFileList();

      const [selectedFiles, excludedFiles] = partition(
        allFiles,
          (file) => allowedFiles.some((allowedFile) => file.id === allowedFile["file_id"]))
      this.#appendExcludedFiles(excludedFiles);
      await this.#sendAllFiles(selectedFiles);

      const finalizeParams = new FormData();
      finalizeParams.append("_method", "put");
      const finalizeResponse = await fetch(this.finalizeUrl, {
        method: "POST",
        headers: { "X-CSRF-Token": this.#authenticityToken },
        body: finalizeParams
      });
      await finalizeResponse.json();

      $(".loading-wrapper .loading-img").remove();
      if (finalizeResponse.ok) {
        $(".loading-wrapper .waiting-text").text("アップロードが完了しました。");
      } else {
        $(".loading-wrapper .waiting-text").text("アップロードが完了しました。");
      }
      $(".main-box #file-picker").val("");
    }

    #appendLoadingWrapper() {
      const $loadingWrapper = $("<div/>").attr({
        class: "loading-wrapper",
        style: "margin-top: 50px;"
      });
      const $loadingImg = $("<img/>").attr({
        src: "/assets/img/loading.gif",
        class: "loading-img",
      });
      const $waitingText = $("<p/>")
        .text("アップロードが完了するまでお待ちください。")
        .attr({class: "waiting-text d-inline-block"});
      $(".progress .progress-info").prepend($loadingWrapper);
      $($loadingWrapper).append($waitingText);
      $($loadingWrapper).append($loadingImg);
    }

    #appendExcludedFiles(excludedFilesAry) {
      if (!excludedFilesAry || excludedFilesAry.length === 0) {
        return;
      }

      const excludedFiles = excludedFilesAry.map((file) => file.file.name).join("・");
      const $excludedFilesWrapper = $("<div/>").attr({
        class: "excluded-files-wrapper",
      });
      const $alertP = $("<p/>")
        .attr("class", "mt-2")
        .text(
          `以下のファイルは許可された拡張子ではないため、アップロードできませんでした。`
        );
      const $excludedFilesP = $("<p/>")
        .attr("class", "excluded-files")
        .attr("style", "margin-left: 1em;")
        .text(excludedFiles);
      $(".progress .loading-wrapper").before($excludedFilesWrapper);
      $($excludedFilesWrapper).append($alertP);
      $($excludedFilesWrapper).append($excludedFilesP);
    }

    async #sendAllFiles(files) {
      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        await this.#sendOneFile(file.id, file.file);
      }
    }

    #setInitParams(files, formData) {
      files.forEach((file) => {
        formData.append("item[files][][file_id]", file.id);
        formData.append("item[files][][filename]", file.file.name);
        formData.append("item[files][][size]", file.file.size);
      });
      return formData;
    };

    #noUploadableFile(excludedFiles) {
      $(".loading-wrapper .waiting-text").text(
        "アップロードできるファイルがありませんでした。サイト設定を変更するなどしてアップロードし直してください。"
      );
      $(".loading-wrapper .loading-img").remove();
      $("#file-picker").val("");
      this.#appendExcludedFiles(excludedFiles);
    }

    #appendFileList() {
      const $fileList = $("<ol />").attr("class", "file-list");
      $(".progress .progress-info").append($fileList);
    }

    async #sendOneFile(id, file) {
      const chunkSize = 1024 * 1024; //1MBずつ
      const totalChunks = Math.ceil(file.size / chunkSize);
      for (let i = 0; i < totalChunks; i++) {
        const start = i * chunkSize;
        const stop = start + chunkSize;
        const blob = file.slice(start, stop);
        const numChunk = i + 1;
        const formData = new FormData();
        formData.append("item[blob]", new Blob([ blob ], {type: "application/octet-stream"}));
        formData.append("item[part_no]", i);
        formData.append("item[file_id]", id);
        const res = await fetchWithRetry({
          authenticityToken: this.#authenticityToken,
          url: this.createUrl,
          formData: formData,
          numRetry: 5
        });

        if (res.ok) {
          this.#updateProgress(numChunk, totalChunks, id, file.name);
        }
      }
    }

    #updateProgress(numChunk, totalChunks, id, filename) {
      const progressRate = Math.ceil((100 * numChunk) / totalChunks).toString();
      if ($(`.file-list li[data-id="${id}"]`)[0]) {
        $(`.file-list li[data-id="${id}"] progress`).attr("value", progressRate);
        this.#showCompletedStatus(id, progressRate);
      } else {
        const fileWithoutExtension = getFileWithoutExtension(filename);
        const $newFileWrapper = $("<li />", { "class": fileWithoutExtension, "data-id": id });
        const $newLabel = $("<label />", { for: "file", class: "mr-4", }).text(filename);
        const $newProgress = $("<progress />", { max: "100", value: progressRate });
        $newFileWrapper.append($newLabel);
        $newFileWrapper.append($newProgress);
        $(".progress .file-list").append($newFileWrapper);
        this.#showCompletedStatus(id, progressRate);
      }
    }

    #showCompletedStatus(id, progressRate) {
      if (progressRate !== "100") {
        return;
      }
      if ($(`.file-list li[data-id="${id}"] .completed`).length) {
        return;
      }

      const $completedTag = $("<span />", { "class": "completed ml-1", "style": "width: 30px;" }).text("完了");
      $(`.file-list li[data-id="${id}"]`).append($completedTag);
    }
  }

  return SS_Large_File_Upload;
})();
