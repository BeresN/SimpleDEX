import React from 'react';

export default function LoadingSpinner({ size = "small" }) {
  const sizeClass = size === "small" ? "h-4 w-4" : "h-6 w-6";
  
  return (
    <div className={`animate-spin rounded-full border-2 border-gray-300 border-t-white ${sizeClass}`}></div>
  );
}