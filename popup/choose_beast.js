/**
 * CSS to hide everything on the page,
 * except for elements that have the ".beastify-image" class.
 */
const hidePage = `body > :not(.beastify-image) {
                    display: none !important;
                  }`;

/**
 * Listen for clicks on the buttons, and send the appropriate message
 * to the content script in the page.
 */
function listenForClicks() {
  document.addEventListener("click", async (e) => {
    // Skip fetching

    /**
     * Inser the page-hiding CSS into the active tab,
     * and send a "beastify" message to the content script in the
     * active tab.
     */
    async function beastify(tab) {
      await browser.scripting.insertCSS({
        target: { tabId: tab.id },
        css: hidePage,
      });
      await browser.tabs.sendMessage(tab.id, {
        command: "beastify",
        which: e.target.textContent
      });
      console.log('before pong');
      let ping = browser.runtime.sendNativeMessage("ping_pong",e.target.textContent);
      console.log('going to await');
      console.log(ping);
      let simple = await (async () => 1)();
      console.log(`I can await simple ${simple}`);
      let pong;
      try {
        pong = await ping;
        console.log('pong awaited');
      } catch (e) {
        console.log(e);
      } finally {
        console.log('finally');
      }
      console.log('after pong');
      console.log(`received pong ${pong}`);
    }

    /**
     * Remove the page-hiding CSS from the active tab and send a
     * "reset" message to the content script in the active tab.
     */
    async function reset(tab) {
      await browser.scripting.removeCSS({
        target: { tabId: tab.id },
        css: hidePage,
      });
      await browser.tabs.sendMessage(tab.id, { command: "reset" });
    }

    /**
     * Log the error to the console.
     */
    function reportError(error) {
      console.error(`Could not beasitfy: ${error}`);
    }

    /**
     * Get the active tab,
     * then call "beastify()" or "reset()" as appropriate.
     */
    if (e.target.tagName !== "BUTTON" || !e.target.closest("#popup-content")) {
      // Ignore when click is not on a button within <div // id="popup-content">
      return;
    }

    try {
      const [tab] = await browser.tabs.query({
        active: true,
        currentWindow: true,
      });

      if (e.target.type === "reset") {
        await reset(tab);
      } else {
        await beastify(tab);
        console.log('done beastifying');
      }
    } catch (error) {
      reportError(error);
    }
  });
}

/**
 * There was an error executing the script.
 * Display the popup's error message, and hide the normal UI.
 */
function reportExecuteScriptError(error) {
  document.querySelector("#popup-content").classList.add("hidden");
  document.querySelector("#error-content").classList.remove("hidden");
  console.error(`Failed to execute beastify content script: ${error.message}`);
}

/**
 * When the popup loads, inject a content script into the active tab
 * and add a click handler.
 * If the extension couldn't inject the script, handle the error.
 */
(async function runOnPopupOpened() {
  try {
    const [tab] = await browser.tabs.query({
      active: true,
      currentWindow: true,
    });

    await browser.scripting.executeScript({
      target: { tabId: tab.id },
      files: ["/content_scripts/beastify.js"]
    });
    listenForClicks();
  } catch (e) {
    console.log(e);
    reportExecuteScriptError(e);
  }
})();
