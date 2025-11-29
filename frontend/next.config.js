/** @type {import('next').NextConfig} */

// Polyfill localStorage for SSR
if (typeof window === 'undefined') {
  global.localStorage = {
    getItem: () => null,
    setItem: () => { },
    removeItem: () => { },
    clear: () => { },
  };
}

const nextConfig = {
  webpack: (config) => {
    config.externals.push('pino-pretty', 'lokijs', 'encoding');
    return config;
  },
}

module.exports = nextConfig