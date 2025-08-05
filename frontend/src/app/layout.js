import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata = {
  title: "Smart Search and Rescue Project - Image Collection Portal",
  description: "Contribute to the Smart Search and Rescue research project by uploading your images with age metadata for advanced face recognition algorithm development.",
  keywords: "smart search, rescue, face recognition, image collection, research, IITK",
  authors: [{ name: "Smart Search and Rescue Project Team" }],
  viewport: "width=device-width, initial-scale=1",
  themeColor: "#3498db",
  manifest: "/manifest.json",
  icons: {
    icon: "/next.svg",
    apple: "/next.svg",
  },
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="robots" content="noindex, nofollow" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
      </head>
      <body className={inter.className}>{children}</body>
    </html>
  );
}
