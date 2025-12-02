// app.js
// Login con Cognito (Authorization Code) + intercambio de code por tokens
// y llamada a /pacientes

let accessToken = null;

const statusEl  = document.getElementById("status");
const outputEl  = document.getElementById("output");
const loginBtn  = document.getElementById("loginBtn");
const logoutBtn = document.getElementById("logoutBtn");
const listarBtn = document.getElementById("listarBtn");

// redirect_uri:
// - En localhost usamos la URL actual.
// - En CloudFront forzamos /index.html para que coincida EXACTO con Cognito.
let REDIRECT_URI;
if (
  window.location.hostname === "localhost" ||
  window.location.hostname === "127.0.0.1"
) {
  REDIRECT_URI = window.location.origin + window.location.pathname;
} else {
  REDIRECT_URI = window.location.origin + "/index.html";
}

console.log("REDIRECT_URI usado:", REDIRECT_URI);

// ----------------- Utilidades UI -----------------
function setStatus(text, type = "normal") {
  statusEl.textContent = text;
  statusEl.classList.remove("status-ok", "status-error");
  if (type === "ok") statusEl.classList.add("status-ok");
  if (type === "error") statusEl.classList.add("status-error");
}

function updateUiLoggedIn(userInfo) {
  if (userInfo) {
    const name =
      userInfo.name ||
      userInfo.email ||
      userInfo["cognito:username"] ||
      userInfo.sub ||
      "(usuario sin nombre)";

    setStatus(`Sesión iniciada como ${name}. Ya puedes probar la API.`, "ok");

    const resumen = {
      usuario: {
        sub: userInfo.sub,
        username: userInfo["cognito:username"],
        email: userInfo.email,
        email_verified: userInfo.email_verified,
      },
    };
    outputEl.textContent = JSON.stringify(resumen, null, 2);
  } else {
    setStatus("Sesión iniciada. Ya puedes probar la API.", "ok");
  }

  loginBtn.disabled  = true;
  logoutBtn.disabled = false;
  listarBtn.disabled = false;
}

function updateUiLoggedOut() {
  setStatus("No hay sesión iniciada.");
  loginBtn.disabled  = false;
  logoutBtn.disabled = true;
  listarBtn.disabled = true;
  outputEl.textContent = "(sin datos todavía)";
  accessToken = null;
}

// ----------------- Helpers OAuth2 -----------------

// Decodificar JWT (id_token) sin librerías externas
function decodeJwt(token) {
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
  const padded = base64 + "=".repeat((4 - (base64.length % 4)) % 4);
  const json   = atob(padded);
  return JSON.parse(json);
}

// Leer el parámetro "code" de la URL (?code=...)
function getAuthCodeFromUrl() {
  const params = new URLSearchParams(window.location.search);
  return params.get("code");
}

// Quitar ?code=... de la barra del navegador
function clearQueryFromUrl() {
  const cleanUrl = window.location.origin + window.location.pathname;
  window.history.replaceState(null, "", cleanUrl);
}

// Intercambiar code -> tokens llamando a /oauth2/token de Cognito
async function exchangeCodeForTokens(code) {
  try {
    setStatus("Intercambiando código por tokens...");

    const body = new URLSearchParams({
      grant_type: "authorization_code",
      client_id: CONFIG.CLIENT_ID,
      code: code,
      redirect_uri: REDIRECT_URI,
    });

    const resp = await fetch(CONFIG.COGNITO_DOMAIN + "/oauth2/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: body.toString(),
    });

    const data = await resp.json();
    console.log("Respuesta /oauth2/token:", data);

    if (!resp.ok) {
      setStatus(
        "Error al intercambiar el código: " +
          (data.error_description || data.error || resp.status),
        "error"
      );
      return;
    }

    accessToken = data.access_token || null;
    let userInfo = null;

    if (data.id_token) {
      try {
        userInfo = decodeJwt(data.id_token);
        console.log("Claims de id_token:", userInfo);
      } catch (e) {
        console.error("Error decodificando id_token:", e);
      }
    }

    clearQueryFromUrl();      // limpiamos ?code=...
    updateUiLoggedIn(userInfo);

    if (!accessToken) {
      setStatus(
        "Sesión iniciada pero no se recibió access_token. Revisa configuración.",
        "error"
      );
    } else {
      console.log(
        "Access token recibido (truncado):",
        accessToken.substring(0, 20) + "..."
      );
    }
  } catch (e) {
    console.error(e);
    setStatus("Error al intercambiar el código por tokens.", "error");
  }
}

// ----------------- Init al cargar la página -----------------

(function init() {
  const code = getAuthCodeFromUrl();
  if (code) {
    // Venimos de Cognito con ?code=...
    exchangeCodeForTokens(code);
  } else {
    updateUiLoggedOut();
  }
})();

// ----------------- Eventos de botones -----------------

// Botón: Iniciar sesión
loginBtn.addEventListener("click", () => {
  // IMPORTANTÍSIMO: este URL debe coincidir con el que te muestra Cognito
  const loginUrl =
    CONFIG.COGNITO_DOMAIN +
    "/login" +
    "?client_id=" + encodeURIComponent(CONFIG.CLIENT_ID) +
    "&response_type=code" +
    "&scope=" + encodeURIComponent(CONFIG.SCOPES) +
    "&redirect_uri=" + encodeURIComponent(REDIRECT_URI);

  console.log("Redirigiendo a:", loginUrl);
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
        Authorization: "Bearer " + accessToken,
        "Content-Type": "application/json",
      },
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
        body: parsed,
      },
      null,
      2
    );

    if (resp.ok) {
      setStatus("Llamada a /pacientes correcta.", "ok");
    } else {
      setStatus(
        "La API respondió con error (" + resp.status + "). Revisa el body.",
        "error"
      );
    }
  } catch (err) {
    console.error(err);
    setStatus("Error al llamar a la API. Revisa la consola.", "error");
    outputEl.textContent = String(err);
  }
});
