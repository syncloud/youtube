import { test, expect } from '@playwright/test'
import { signIn } from '../helpers/auth'
import { shoot } from '../helpers/screenshot'

test('SABR-only video Download icon serves the file (forum #652)', async ({ page, context }, testInfo) => {
  await signIn(page)
  await page.getByRole('button', { name: 'Home speed dial' }).hover()
  await page.getByRole('menuitem', { name: 'New download' }).click()
  await page.locator('textarea').first().fill('https://www.youtube.com/watch?v=NokXiX-aznM')
  await page.getByRole('button', { name: 'Start' }).click()

  const card = page.locator('.MuiCard-root', { hasText: '21,000 RPM' })
  await expect(card).toBeVisible()
  await expect(card.getByText('Completed')).toBeVisible({ timeout: 300_000 })
  await shoot(page, testInfo, 'sabr-download-completed')

  const respPromise = context.waitForEvent('response', r => /\/filebrowser\/d\//.test(r.url()))
  await card.getByRole('button', { name: 'Download this file' }).click()
  const resp = await respPromise

  expect(resp.status(), `GET ${resp.url()}`).toBe(200)
})
