// Apollo Nexus Firebase Bridge
// Enhanced configuration with secure dynamic variable handling

// Configuration object with environment variable support
const firebaseConfig = {
  apiKey: typeof process !== 'undefined' && process.env?.FIREBASE_API_KEY 
    ? process.env.FIREBASE_API_KEY 
    : (typeof window !== 'undefined' && window.FIREBASE_CONFIG?.apiKey) || "DEIN_API_KEY",
  authDomain: typeof process !== 'undefined' && process.env?.FIREBASE_AUTH_DOMAIN
    ? process.env.FIREBASE_AUTH_DOMAIN
    : (typeof window !== 'undefined' && window.FIREBASE_CONFIG?.authDomain) || "hannesmitterer-nexus.firebaseapp.com",
  projectId: typeof process !== 'undefined' && process.env?.FIREBASE_PROJECT_ID
    ? process.env.FIREBASE_PROJECT_ID
    : (typeof window !== 'undefined' && window.FIREBASE_CONFIG?.projectId) || "hannesmitterer-nexus",
  storageBucket: typeof process !== 'undefined' && process.env?.FIREBASE_STORAGE_BUCKET
    ? process.env.FIREBASE_STORAGE_BUCKET
    : (typeof window !== 'undefined' && window.FIREBASE_CONFIG?.storageBucket) || "hannesmitterer-nexus.appspot.com",
  messagingSenderId: typeof process !== 'undefined' && process.env?.FIREBASE_MESSAGING_SENDER_ID
    ? process.env.FIREBASE_MESSAGING_SENDER_ID
    : (typeof window !== 'undefined' && window.FIREBASE_CONFIG?.messagingSenderId) || "DEINE_ID",
  appId: typeof process !== 'undefined' && process.env?.FIREBASE_APP_ID
    ? process.env.FIREBASE_APP_ID
    : (typeof window !== 'undefined' && window.FIREBASE_CONFIG?.appId) || "DEINE_APP_ID",
  measurementId: typeof process !== 'undefined' && process.env?.FIREBASE_MEASUREMENT_ID
    ? process.env.FIREBASE_MEASUREMENT_ID
    : (typeof window !== 'undefined' && window.FIREBASE_CONFIG?.measurementId) || "G-DEINE_MEASUREMENT_ID"
};

// Configuration validation
function validateConfig(config) {
  const requiredFields = ['apiKey', 'authDomain', 'projectId', 'storageBucket', 'messagingSenderId', 'appId'];
  const missingFields = requiredFields.filter(field => !config[field] || config[field].startsWith('DEIN'));
  
  if (missingFields.length > 0) {
    console.warn(`Nexus: Configuration incomplete. Missing or placeholder values for: ${missingFields.join(', ')}`);
    return false;
  }
  return true;
}

// Initialisierung mit Fallback-Logik
try {
    if (typeof firebase !== 'undefined') {
        const isValid = validateConfig(firebaseConfig);
        if (isValid) {
            firebase.initializeApp(firebaseConfig);
            console.log("Nexus: Firebase-Verschränkung aktiv.");
        } else {
            console.warn("Nexus: Quarantäne-Modus. Konfiguration unvollständig - Nutze lokale Vakuum-Mimikry.");
        }
    } else {
        console.warn("Nexus: Firebase SDK nicht verfügbar. Quarantäne-Modus aktiv.");
    }
} catch (e) {
    console.warn("Nexus: Quarantäne-Modus. Nutze lokale Vakuum-Mimikry.", e.message);
}

// Export configuration for module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { firebaseConfig, validateConfig };
}
