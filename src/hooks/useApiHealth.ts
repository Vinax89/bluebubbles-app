import { useEffect, useState } from 'react';

export type HealthStatus = {
  status: 'ok' | 'down' | 'unknown';
  version?: string;
  uptime?: number;
  node?: string;
  error?: string;
};

export function useApiHealth(apiBase?: string, intervalMs = 15000) {
  const [health, setHealth] = useState<HealthStatus>({ status: 'unknown' });

  useEffect(() => {
    let timer: any;
    const url = (apiBase || import.meta.env.VITE_API_URL || '').replace(/\/$/, '');
    async function ping() {
      if (!url) {
        setHealth({ status: 'down', error: 'VITE_API_URL not set' });
        return;
      }
      try {
        const r = await fetch(`${url}/healthz`);
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        const json = await r.json();
        setHealth({ status: 'ok', version: json.version, uptime: json.uptime, node: json.node });
      } catch (e: any) {
        setHealth({ status: 'down', error: e?.message || 'fetch failed' });
      }
    }
    ping();
    timer = setInterval(ping, intervalMs);
    return () => clearInterval(timer);
  }, [apiBase, intervalMs]);

  return health;
}
