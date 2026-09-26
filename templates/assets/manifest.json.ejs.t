<%_
  const manifest = {
    name: pkg.name,
    short_name: pkg.name,
    description: pkg.description || "",
    categories: ["technology"],
    lang: "en",
    start_url: "/?source=pwa",
    scope: "/",
    display: "standalone",
    orientation: "portrait-primary",
    background_color: "#ffffff",
    theme_color: "#ffffff",
    icons: [
      { src: "/img/favicons/pwa-64x64.png", sizes: "64x64", type: "image/png" },
      { src: "/img/favicons/pwa-192x192.png", sizes: "192x192", type: "image/png" },
      { src: "/img/favicons/pwa-512x512.png", sizes: "512x512", type: "image/png" },
      { src: "/img/favicons/maskable-icon-512x512.png", sizes: "512x512", type: "image/png", purpose: "maskable" }
    ]
  };
-%>
<%- JSON.stringify(manifest, null, 2) %>