import React, { useState } from "react";
import { Emulator } from "android-emulator-webrtc/emulator";

// Get port from URL: ?port=8080 or ?port=8081
const params = new URLSearchParams(window.location.search);
const port = params.get("port") || "8080";
const EMULATOR_GRPC = `http://localhost:${port}`;

function App() {
  const [status, setStatus] = useState("disconnected");

  return (
    <div style={styles.container}>
      <div style={styles.emulatorWrapper}>
        <Emulator
          uri={EMULATOR_GRPC}
          view="webrtc"
          poll={true}
          width={400}
          height={800}
          muted={true}
          volume={1.0}
          onStateChange={(s) => setStatus(s)}
          onError={(e) => console.error("Error:", e)}
        />
      </div>
      <div style={styles.statusBar}>
        :{port} • {status}
      </div>
    </div>
  );
}

const styles = {
  container: {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    minHeight: "100vh",
    backgroundColor: "#0a0a0a",
    margin: 0,
    padding: 20,
  },
  emulatorWrapper: {
    borderRadius: 24,
    overflow: "hidden",
    boxShadow: "0 0 60px rgba(0, 0, 0, 0.8)",
  },
  statusBar: {
    marginTop: 12,
    fontSize: 11,
    color: "#444",
    textTransform: "uppercase",
    letterSpacing: 2,
  },
};

export default App;
