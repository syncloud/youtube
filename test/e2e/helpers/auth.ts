import { Page, expect } from '@playwright/test'

const deviceUser = required('PLAYWRIGHT_DEVICE_USER')
const devicePassword = required('PLAYWRIGHT_DEVICE_PASSWORD')

function required(name: string): string {
  const v = process.env[name]
  if (!v) throw new Error(`${name} is required`)
  return v
}

export async function signIn(page: Page) {
  await page.goto('/')
  await page.locator('#username-textfield').fill(deviceUser)
  await page.locator('#password-textfield').fill(devicePassword)
  await page.locator('#sign-in-button').click()
  await expect(page.getByText('No active downloads')).toBeVisible()
}
