// Apollo Nexus Firebase Bridge
const firebaseConfig = {
  apiKey: "DEIN_API_KEY",
  authDomain: "hannesmitterer-nexus.firebaseapp.com",
  projectId: "hannesmitterer-nexus",
  storageBucket: "hannesmitterer-nexus.appspot.com",
  messagingSenderId: "DEINE_ID",
  appId: "DEINE_APP_ID",
  measurementId: "G-DEINE_MEASUREMENT_ID"
};

// Initialisierung mit Fallback-Logik
try {
    firebase.initializeApp(firebaseConfig);
    console.log("Nexus: Firebase-Verschränkung aktiv.");
} catch (e) {
    console.warn("Nexus: Quarantäne-Modus. Nutze lokale Vakuum-Mimikry.");
}
