// script.js
window.addEventListener("message", (event) => {
  const d = event.data;
  const el = document.getElementById("blackout");

  if (!d || !d.action) return;

  if (d.action === "showBlackout") {
    el.style.display = "block";
    // Force reflow to ensure the browser paints
    void el.offsetWidth;
    el.classList.remove("hidden");

    // enable transitions after it's visible (so fade-in does NOT happen)
    requestAnimationFrame(() => {
      el.classList.add("ready");
    });
  } else if (d.action === "hideBlackout") {
    el.classList.add("hidden");
    // wait for transition end then hide display
    el.addEventListener("transitionend", function handler() {
      el.style.display = "none";
      el.classList.remove("ready"); // disable transitions until next use
      el.removeEventListener("transitionend", handler);
    });
  }
});
