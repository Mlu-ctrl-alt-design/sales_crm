/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,jsx,ts,tsx}',
    './components/**/*.{js,jsx,ts,tsx}',
    './context/**/*.{js,jsx,ts,tsx}',
  ],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      colors: {
        brand: '#0086c9',
        'brand-dark': '#026aa2',
        'brand-light': '#0ba5ec',
        'brand-50': '#f0f9ff',
      },
    },
  },
  plugins: [],
};
