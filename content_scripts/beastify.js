(function () {
  /**
   * Check and set a global guard variable to ensure that if this
   * content script is injected into a page again, it return (and does
   * nothing).
   */
  if (window.hasRun) {
    return;
  }
  window.hasRun = true;

  function insertBeast(beastURL) {
    removeExistingBeasts();
    let beastHeading = document.createElement("h1");
    beastHeading.innerHTML = beastURL;
    beastHeading.className = "beastify-image";
    document.body.appendChild(beastHeading);
  }

  function removeExistingBeasts() {
    let existingBeasts = document.querySelectorAll(".beastify-image");
    for (let beast of existingBeasts) {
      beast.remove();
    }
  }

  browser.runtime.onMessage.addListener((message) => {
    if (message.command === "beastify") {
      insertBeast(message.which);
    } else if (message.command === "reset") {
      removeExistingBeasts();
    }
  });
})();
