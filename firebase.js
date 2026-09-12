// Firebase Web SDK Configuration
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-analytics.js";

export const firebaseConfig = {
  apiKey: "AIzaSyAn1AxnVcawaKZUWcGYG9tqfqpExvav2bY",
  authDomain: "jiogenie.firebaseapp.com",
  projectId: "jiogenie",
  storageBucket: "jiogenie.firebasestorage.app",
  messagingSenderId: "107335383664",
  appId: "1:107335383664:web:a8a10b7f772662ad51d2b5",
  measurementId: "G-WHJ9QVQE6B"
};

export const app = initializeApp(firebaseConfig);
export const analytics = typeof window !== 'undefined' ? getAnalytics(app) : null;
