/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        gym: {
          50: '#f7fee7',
          100: '#ecfccb',
          400: '#a3e635',
          500: '#84cc16',
          brand: '#bef264', // Neon Lime
          900: '#0c4a6e',
          dark: '#0f172a',
          accent: '#8b5cf6',
        }
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
