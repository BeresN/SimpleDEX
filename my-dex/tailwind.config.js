// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  important: true,
  content: [
    './src/app/**/*.{js,ts,jsx,tsx}',
    './src/components/**/*.{js,ts,jsx,tsx}',
    './src/pool/**/*.{js,ts,jsx,tsx}',
    './src/send/**/*.{js,ts,jsx,tsx}',
    './src/swap/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};