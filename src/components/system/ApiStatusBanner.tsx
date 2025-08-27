import React from 'react';
import { useApiHealth } from '../../hooks/useApiHealth';

export default function ApiStatusBanner() {
  const health = useApiHealth();

  if (health.status === 'ok') return null;

  const msg = health.status === 'down'
    ? `API unreachable${health.error ? `: ${health.error}` : ''}`
    : 'Checking API…';

  return (
    <div className="w-full bg-yellow-500 text-black text-sm py-2 px-4">
      <div className="max-w-6xl mx-auto flex items-center justify-between">
        <span>Offline/local mode — {msg}. Some data may be cached only.</span>
        <a
          href=""
          onClick={(e) => { e.preventDefault(); location.reload(); }}
          className="underline"
        >
          Retry
        </a>
      </div>
    </div>
  );
}
