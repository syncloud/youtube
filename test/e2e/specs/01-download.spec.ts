import { test, expect } from '@playwright/test'
import { signIn } from '../helpers/auth'
import { shoot } from '../helpers/screenshot'

test.describe('youtube webui', () => {
  test('user can sign in and reach the empty downloads view', async ({ page }, testInfo) => {
    await signIn(page)
    await shoot(page, testInfo, 'signed-in')
  })

  test('user can start a download and see it complete', async ({ page }, testInfo) => {
    await signIn(page)
    const speedDial = page.getByRole('button', { name: 'Home speed dial' })
    await speedDial.hover()
    await page.getByRole('menuitem', { name: 'New download' }).click()
    await page.locator('textarea').first().fill('https://m.youtube.com/watch?v=x983nr0lXwo')
    await page.getByRole('button', { name: 'Start' }).click()
    await expect(page.getByText('Syncloud Introduction')).toBeVisible()
    await expect(page.getByText('Completed')).toBeVisible({ timeout: 120_000 })
    await shoot(page, testInfo, 'download-completed')
  })
})
