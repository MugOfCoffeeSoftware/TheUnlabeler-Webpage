// Holen einer Sprachdatei
async function fetchLanguageData(lang) {
  const response = await fetch(`languages/${lang}.json`);
  return response.json();
}

// Funktion für click Event um die Sprache zu ändern
 function changeLanguage(lang) {
  localStorage.setItem("language", lang);
  fetchLanguageData(lang).then(langData => {
    updateContent(langData);
    updateImages(langData);
    updateLinks(langData);
  })
  .catch(err => console.error(err));
}

// Aktualisieren des Contents
function updateContent(langData) {
  document.querySelectorAll("[data-i18n]").forEach((element) => {
    const key = element.getAttribute("data-i18n");
    element.innerHTML = langData[key];
  });
}

// Aktualisieren der Bilder
function updateImages(langData) {
  document.querySelectorAll("[data-i18n-img]").forEach((element) => {
    const key = element.getAttribute("data-i18n-img");
    element.src = langData[key];
  });
}

// Aktualisieren der Links
function updateLinks(langData) {
  document.querySelectorAll("[data-i18n-link]").forEach((element) => {
    const key = element.getAttribute("data-i18n-link");
    element.href = langData[key];
  });
}

// Initiales Event um entweder die zuvor gewählte Sprache zu setzen oder Deutsch als Fallback
window.addEventListener("DOMContentLoaded", async () => {
  const userPreferredLanguage = localStorage.getItem("language") || "en";
  const langData = await fetchLanguageData(userPreferredLanguage);
  updateContent(langData);
  updateImages(langData);
  updateLinks(langData);
});

// Ensure language is maintained when navigating to new pages
document.querySelectorAll(".dropdown-item").forEach(item => {
  item.addEventListener("click", (event) => {
    event.preventDefault();
    const lang = event.target.getAttribute("onclick").match(/'([^']+)'/)[1];
    changeLanguage(lang);
    window.location.href = event.target.href;
  });
});
