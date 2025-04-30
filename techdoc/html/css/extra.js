// requires addition of
// extra_javascript:
//   - javascripts/extra.js
// into mkdocs.yml

// generate a tooltip balloon
document.addEventListener("DOMContentLoaded", function() {
  const helpElements = document.querySelectorAll("[data-help]");

  helpElements.forEach(element => {
    let balloon;

    element.addEventListener("mouseover", function(e) {
      balloon = document.createElement("div");
      balloon.className = "help-balloon";

      // Add optional title bar if data-help-title exists
      const titleText = element.getAttribute("data-help-title");
      if (titleText) {
        const titleBar = document.createElement("div");
        titleBar.className = "title-bar";
        titleBar.textContent = titleText;
        balloon.appendChild(titleBar);
      }

      // Add main help text
      const helpText = document.createElement("div");
      helpText.textContent = element.getAttribute("data-help");
      balloon.appendChild(helpText);

      // Position balloon
      const rect = element.getBoundingClientRect();
      balloon.style.position = "absolute";
      balloon.style.left = `${rect.left + window.scrollX}px`;
      balloon.style.top = `${rect.bottom + window.scrollY + 5}px`;

      document.body.appendChild(balloon);
    });

    element.addEventListener("mouseout", function() {
      if (balloon) {
        balloon.remove();
        balloon = null;
      }
    });
  });
});