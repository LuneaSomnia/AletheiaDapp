import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";

if (import.meta.env.VITE_USE_MOCKS === "true") {
  (async function() {
    const { worker } = await import("./mocks/browser");
    await worker.start();
  })();
}

createRoot(document.getElementById("root")).render(<App />);
