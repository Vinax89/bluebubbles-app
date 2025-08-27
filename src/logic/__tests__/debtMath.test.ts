import { describe, it, expect } from 'vitest';

// Example math: avalanche ordering by APR, then balance
type Debt = { id: string; name: string; apr: number; balance: number };

function avalancheOrder(debts: Debt[]): Debt[] {
  return [...debts].sort((a, b) => {
    if (b.apr !== a.apr) return b.apr - a.apr;
    return b.balance - a.balance;
  });
}

describe('avalancheOrder', () => {
  it('orders by APR desc then balance desc', () => {
    const debts: Debt[] = [
      { id: 'a', name: 'A', apr: 26.99, balance: 20306.98 },
      { id: 'b', name: 'B', apr: 23.99, balance: 4833.57 },
      { id: 'c', name: 'C', apr: 26.99, balance: 6126.44 },
    ];
    const out = avalancheOrder(debts).map(d => d.id);
    expect(out).toEqual(['a', 'c', 'b']); // a & c share APR; a has higher balance
  });
});
