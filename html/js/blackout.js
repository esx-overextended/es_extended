window.addEventListener("message", (event) => {
  const d = event.data;
  const el = document.getElementById("blackout");

  if (!d || !d.action) return;

  if (d.action === "showBlackout") {
    // 0. Turn off transitions
    el.classList.remove("ready");

    // 1. Make blackout instantly visible (full black)
    el.classList.remove("hidden");

    // 2. Force reflow
    void el.offsetWidth;

    // 3. Enable transitions for next fade-out
    requestAnimationFrame(() => {
      el.classList.add("ready");
    });
  } else if (d.action === "hideBlackout") {
    // 1. Trigger opacity transition (fade to 0)
    el.classList.add("hidden");

    // 2. When fade finishes, remove `ready` to avoid fade-in later
    const handler = () => {
      el.classList.remove("ready");
      el.removeEventListener("transitionend", handler);
    };

    el.addEventListener("transitionend", handler);
  }
});
