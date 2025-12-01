// app.js
// Lógica de login con Cognito Hosted UI + llamada a /pacientes

let accessToken = null;

const statusEl = document.getElementById("status");
const outputEl = document.getElementById("output");
const loginBtn = document.getElementById("loginBtn");
const logoutBtn = document.getElementById("logoutBtn");
const listarBtn = document.getElementById("listarBtn");

// redirect_uri = esta misma página (CloudFront o S3 static)
const REDIRECT_URI = window.location.origin + window.location.pathname;

function setStatus(text, type = "normal") {
  statusEl.textContent = text;
  statusEl.classList.remove("status-ok", "status-error");
  if (type === "ok") statusEl.classList.add("status-ok");
  if (type === "error") statusEl.classList.add("status-error");
}

function parseHashTokens() {
  if (!window.location.hash) return null;
  const hash = window.location.hash.substring(1); // quitar "#"
  const params = new URLSearchParams(hash);
  const at = params.get("access_token");
  const idt = params.get("id_token");
  const exp = params.get("expires_in");
  if (!at) return null;
  return { accessToken: at, idToken: idt, expiresIn: exp };
}

function clearHashFromUrl() {
  if (window.location.hash) {
    history.replaceState(null, "", window.location.pathname + window.location.search);
  }
}

function updateUiLoggedIn() {
  setStatus("Sesión iniciada. Ya puedes probar la API.", "ok");
  loginBtn.disabled = true;
  logoutBtn.disabled = false;
  listarBtn.disabled = false;
}

function updateUiLoggedOut() {
  setStatus("No hay sesión iniciada.");
  loginBtn.disabled = false;
  logoutBtn.disabled = true;
  listarBtn.disabled = true;
  outputEl.textContent = "(sin datos todavía)";
  accessToken = null;
}

// Inicialización: revisar si venimos del Hosted UI con tokens en el hash
(function init() {
  const tokens = parseHashTokens();
  if (tokens && tokens.accessToken) {
    accessToken = tokens.accessToken;
    clearHashFromUrl();
    updateUiLoggedIn();
    console.log("Access token recibido (truncado):", accessToken.substring(0, 20) + "...");
  } else {
    updateUiLoggedOut();
  }
})();

// Botón: Iniciar sesión
loginBtn.addEventListener("click", () => {
  const loginUrl =
    CONFIG.COGNITO_DOMAIN +
    "/login" +
    "?client_id=" + encodeURIComponent(CONFIG.CLIENT_ID) +
    "&response_type=token" + // implicit flow
    "&scope=" + encodeURIComponent(CONFIG.SCOPES) +
    "&redirect_uri=" + encodeURIComponent(REDIRECT_URI);

  window.location.href = loginUrl;
});

// Botón: Cerrar sesión
logoutBtn.addEventListener("click", () => {
  const logoutUrl =
    CONFIG.COGNITO_DOMAIN +
    "/logout" +
    "?client_id=" + encodeURIComponent(CONFIG.CLIENT_ID) +
    "&logout_uri=" + encodeURIComponent(REDIRECT_URI);

  updateUiLoggedOut();
  window.location.href = logoutUrl;
});

// Botón: Listar pacientes
listarBtn.addEventListener("click", async () => {
  if (!accessToken) {
    setStatus("No hay token de acceso, vuelve a iniciar sesión.", "error");
    return;
  }

  setStatus("Llamando a /pacientes...");
  outputEl.textContent = "Cargando...";

  try {
    const resp = await fetch(CONFIG.API_BASE_URL + "/pacientes", {
      method: "GET",
      headers: {
        "Authorization": "Bearer " + accessToken,
        "Content-Type": "application/json"
      }
    });

    const text = await resp.text();
    let parsed;
    try {
      parsed = JSON.parse(text);
    } catch {
      parsed = text;
    }

    outputEl.textContent = JSON.stringify(
      {
        status: resp.status,
        ok: resp.ok,
        body: parsed
      },
      null,
      2
    );

    if (resp.ok) {
      setStatus("Llamada a /pacientes correcta.", "ok");
    } else {
      setStatus("La API respondió con error (" + resp.status + "). Revisa el body.", "error");
    }
  } catch (err) {
    console.error(err);
    setStatus("Error al llamar a la API. Revisa la consola.", "error");
    outputEl.textContent = String(err);
  }
});
