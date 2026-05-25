import { test, expect } from '@playwright/test'
import { signIn } from '../helpers/auth'
import { shoot } from '../helpers/screenshot'

// A short non-SABR video that yt-dlp 2025.10.22 can still download.
// Verifies the happy path: yt-dlp completes -> savedFilePath is set ->
// the Home Download icon serves the file with 200.
test('non-SABR YouTube video Download icon serves the file', async ({ page, context }, testInfo) => {
  await signIn(page)
  await page.getByRole('button', { name: 'Home speed dial' }).hover()
  await page.getByRole('menuitem', { name: 'New download' }).click()
  await page.locator('textarea').first().fill('https://m.youtube.com/watch?v=x983nr0lXwo')
  await page.getByRole('button', { name: 'Start' }).click()

  const card = page.locator('.MuiCard-root', { hasText: 'Syncloud Introduction' })
  await expect(card).toBeVisible()
  await expect(card.getByText('Completed')).toBeVisible({ timeout: 180_000 })
  await shoot(page, testInfo, 'download-completed')

  const respPromise = context.waitForEvent('response', r => /\/filebrowser\/d\//.test(r.url()))
  await card.getByRole('button', { name: 'Download this file' }).click()
  const resp = await respPromise

  expect(resp.status(), `GET ${resp.url()}`).toBe(200)
})
