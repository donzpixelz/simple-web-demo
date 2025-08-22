// /js/loaded-at.js
(function () {
    // If you want the moment the DOM is ready (fast), use DOMContentLoaded:
    document.addEventListener("DOMContentLoaded", () => {
        const el = document.getElementById("page-loaded-at");
        if (!el) return;

        // Capture the timestamp once so it never changes
        const loadedAt = new Date();

        // Machine-readable ISO for the <time> element
        el.dateTime = loadedAt.toISOString();

        // Human-readable, localized string (uses the user's locale)
        const dtf = new Intl.DateTimeFormat(undefined, {
            dateStyle: "medium",
            timeStyle: "short",
        });
        el.textContent = dtf.format(loadedAt);
    });

    // If instead you want the moment *everything* (images, CSS) finished loading,
    // swap the handler above for this:
    // window.addEventListener("load", () => { ...same body... });
})();
