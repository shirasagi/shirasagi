function SS_Large_File_Upload($el, urls) {
  this.$el = $el;
  this.urls = urls;

  this.render();
}

SS_Large_File_Upload.prototype.render = function () {
  this.$el.on('click', () => {
    $(".main-box .import-button").prop("disabled", true);
    $('.progress dd').empty();
    this.appendLoadingWrapper();
    this.importFiles();
  });

  $(".main-box #file-picker").on("change", () => {
    $(".main-box .import-button").prop("disabled", false);
  });
}

SS_Large_File_Upload.prototype.importFiles = function () {
  let filesFormData = new FormData();
  let filenamesFormData = new FormData();
  let allFiles = this.$el.prev().prop("files");
  let arrayFiles = Array.from(allFiles);
  let selectedFilenames = this.setFilenames(arrayFiles, filenamesFormData);
  let selectedFiles = this.setFiles(arrayFiles, filesFormData);

  fetch(this.urls["initUrl"], {
    method: "POST",
    body: selectedFilenames,
  })
    .then((response) => response.json())
    .then((data) => {
      let formData = new FormData();
      let resFiles = JSON.stringify(data["files"]);
      data["resFiles"] = resFiles;
      data["selectedFiles"] = selectedFiles;

      if (resFiles === "{}") {
        this.noUploadableFile(data["excluded_files"]);
        return
      }

      this.appendFileList();
      this.appendExcludedFiles(data["excluded_files"]);
      let promises = this.promisesPush(formData, data);
      Promise.all(promises).then(() => {
        fetch(this.urls["finalizeUrl"], {
          method: "PUT",
          body: formData,
        })
          .then((response) => {
            $(".loading-wrapper .loading-img").remove();
            $(".loading-wrapper .waiting-text").text("アップロードが完了しました。");
            $(".main-box #file-picker").val("");
          })
          .catch((err) => {
            console.log(err);
          });
      });
    })
    .catch((err) => {
      console.log(err);
    });
};

SS_Large_File_Upload.prototype.appendLoadingWrapper = function() {
  let $loadingWrapper = $("<div/>").attr({
    class: "loading-wrapper",
    style: "margin-top: 50px;"
  });
  let $loadingImg = $("<img/>").attr({
    src: "/assets/img/loading.gif",
    class: "loading-img",
  });
  let $waitingText = $("<p/>")
    .text("アップロードが完了するまでお待ちください。")
    .attr({ class: "waiting-text d-inline-block" });
  $(".progress dd").prepend($loadingWrapper);
  $($loadingWrapper).append($waitingText);
  $($loadingWrapper).append($loadingImg);
};

SS_Large_File_Upload.prototype.appendExcludedFiles = function(excludedFilesAry) {
  let excludedFiles = excludedFilesAry.join("・");
  let $excludedFilesWrapper = $("<div/>").attr({
    class: "excluded-files-wrapper",
  });
  let $alertP = $("<p/>")
    .attr("class", "mt-2")
    .text(
      `以下のファイルは許可された拡張子ではないため、アップロードできませんでした。`
    );
  let $excludedFilesP = $("<p/>")
    .attr("class", "excluded-files")
    .attr("style", "margin-left: 1em;")
    .text(excludedFiles);
  $(".progress .loading-wrapper").before($excludedFilesWrapper);
  $($excludedFilesWrapper).append($alertP);
  $($excludedFilesWrapper).append($excludedFilesP);
};

SS_Large_File_Upload.prototype.promisesPush = function (formData, data) {
  let promises = [];
  data["selectedFiles"].forEach((file) => {
    if (!data["files"][file.name]) {
      return;
    }
    let promise = this.sendFile(file);
    formData.append("files", data["resFiles"]);
    formData.append("cur_site_id", data["cur_site_id"]);
    promises.push(promise);
  });

  return promises;
};

SS_Large_File_Upload.prototype.setFilenames = function(files, filenamesFormData) {
  files.forEach((file) => {
    filenamesFormData.append("filenames[]", file.name);
  });
  return filenamesFormData;
};

SS_Large_File_Upload.prototype.setFiles = function(files, filesFormData) {
  files.forEach((file, i) => {
    filesFormData.append("files[]", files[i], files[i].name);
  });
  return filesFormData;
};

SS_Large_File_Upload.prototype.noUploadableFile = function (excluded_files) {
  $(".loading-wrapper .waiting-text").text(
    "アップロードできるファイルがありませんでした。サイト設定を変更するなどしてアップロードし直してください。"
  );
  $(".loading-wrapper .loading-img").remove();
  $("#file-picker").val("");
  this.appendExcludedFiles(excluded_files);
};

SS_Large_File_Upload.prototype.appendFileList = function() {
  let $fileList = $("<ol />").attr("class", "file-list");
  $(".progress dd").append($fileList);
};

SS_Large_File_Upload.prototype.sendFile = async function(file) {
  let chunkSize = 1024 * 1024; //1MBずつ
  let totalChunks = Math.ceil(file.size / chunkSize);
  for (let i = 0; i < totalChunks; i++) {
    let start = i * chunkSize;
    let stop = start + chunkSize;
    let blob = file.slice(start, stop);
    let numChunk = i + 1;
    const formData = new FormData();
    formData.append(
      "blob",
      new Blob([blob], { type: "application/octet-stream" })
    );
    formData.append("filename", file.name);
    await this.fetch_retry({
      createUrl: this.urls["createUrl"],
      formData: formData,
      numRetry: 5,
      numChunk: numChunk,
      totalChunks: totalChunks,
      filename: file.name,
    }).catch((err) => {
      console.log(err);
    });
  }
};

SS_Large_File_Upload.prototype.fetch_retry = function(data) {
  return fetch(data["createUrl"], {
    method: "POST",
    body: data["formData"],
  })
    .then((res) => {
      if (res.ok) {
        this.updateProgress(
          data["numChunk"],
          data["totalChunks"],
          data["filename"]
        );
      }
    })
    .catch((err) => {
      if (data["numRetry"] === 0) throw err;
      data["numRetry"] -= 1;
      return this.fetch_retry(data);
    });
};

SS_Large_File_Upload.prototype.updateProgress = function(numChunk, totalChunks, filename) {
  let progressRate = Math.ceil((100 * numChunk) / totalChunks).toString();
  let fileWithoutExtension = this.getFileWithoutExtension(filename);
  if ($(".file-list li").hasClass(fileWithoutExtension)) {
    $(`.file-list li.${fileWithoutExtension} progress`).attr(
      "value",
      progressRate
    );
    this.showCompletedStatus(filename, progressRate);
  } else {
    let $newFileWrapper = $("<li />").attr("class", fileWithoutExtension);
    let $newLabel = $("<label />").text(filename).attr({
      for: "file",
      class: "mr-4",
    });
    let $newProgress = $("<progress />").attr({
      max: "100",
      value: progressRate,
    });
    $newFileWrapper.append($newLabel);
    $newFileWrapper.append($newProgress);
    $(".progress .file-list").append($newFileWrapper);
    this.showCompletedStatus(filename, progressRate);
  }
};

SS_Large_File_Upload.prototype.showCompletedStatus = function(filename, progressRate) {
  let fileWithoutExtension = this.getFileWithoutExtension(filename);
  if (progressRate !== "100") {
    return;
  }
  if ($(`.file-list .completed-${fileWithoutExtension}`).length) {
    return;
  }
  let $completedTag = $("<span />")
    .text("完了")
    .attr("class", `completed-${fileWithoutExtension} ml-1`)
    .attr("style", "width: 30px");
  $(`li.${fileWithoutExtension}`).append($completedTag);
};

SS_Large_File_Upload.prototype.getFileWithoutExtension = function(filename) {
  return filename.replace(/\.[^/.]+$/, "");
};
