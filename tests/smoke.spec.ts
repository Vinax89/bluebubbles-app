import { test, expect } from '@playwright/test';

test('app loads and shows title', async ({ page }) => {
  await page.goto('/');
  const title = await page.title();
  expect(title).toBeTruthy();
  // Try to find a top-level header or app root
  await expect(page.locator('body')).toContainText(/ChatPay|Project Thrive|Dashboard/i);
});
