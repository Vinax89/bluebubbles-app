import { describe, it, expect } from 'vitest';

type BNPL = { id: string; total: number; termMonths: number };

function monthly(bnpl: BNPL) {
  return Math.round((bnpl.total / bnpl.termMonths) * 100) / 100;
}

describe('bnpl monthly calc', () => {
  it('splits evenly to cents', () => {
    expect(monthly({ id: 'x', total: 1000, termMonths: 10 })).toBe(100);
    expect(monthly({ id: 'y', total: 1161.84, termMonths: 12 })).toBe(96.82);
  });
});
