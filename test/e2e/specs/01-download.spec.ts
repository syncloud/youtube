import { test, expect, Page } from '@playwright/test'
import { shoot } from '../helpers/screenshot'

const deviceUser = required('PLAYWRIGHT_DEVICE_USER')
const devicePassword = required('PLAYWRIGHT_DEVICE_PASSWORD')

function required(name: string): string {
  const v = process.env[name]
  if (!v) throw new Error(`${name} is required`)
  return v
}

async function signIn(page: Page) {
  await page.goto('/')
  await page.locator('#username-textfield').fill(deviceUser)
  await page.locator('#password-textfield').fill(devicePassword)
  await page.locator('#sign-in-button').click()
  await expect(page.getByText('No active downloads')).toBeVisible()
}

test.describe('youtube webui', () => {
  test('user can sign in and reach the empty downloads view', async ({ page }, testInfo) => {
    await signIn(page)
    await shoot(page, testInfo, 'signed-in')
  })

  test('user can start a download and see it complete', async ({ page }, testInfo) => {
    await signIn(page)
    await page.getByRole('button', { name: 'Home speed dial' }).click()
    await page.getByRole('button', { name: 'New download' }).click()
    await page.locator('textarea').fill('https://m.youtube.com/watch?v=x983nr0lXwo')
    await page.getByRole('button', { name: 'Start' }).click()
    await expect(page.getByText('Syncloud Introduction')).toBeVisible()
    await expect(page.getByText('Completed')).toBeVisible({ timeout: 120_000 })
    await shoot(page, testInfo, 'download-completed')
  })
})
