import pytest
from os.path import dirname, join
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from subprocess import check_output
from syncloudlib.integration.hosts import add_host_alias
from selenium.webdriver.support import expected_conditions as EC

DIR = dirname(__file__)
TMP_DIR = '/tmp/syncloud/ui'


@pytest.fixture(scope="session")
def module_setup(request, device, artifact_dir, ui_mode):
    def module_teardown():
        device.activated()
        device.run_ssh('mkdir -p {0}'.format(TMP_DIR), throw=False)
        device.run_ssh('journalctl > {0}/journalctl.ui.{1}.log'.format(TMP_DIR, ui_mode), throw=False)
        device.scp_from_device('{0}/*'.format(TMP_DIR), join(artifact_dir, 'log'))
        check_output('cp /videos/* {0}'.format(artifact_dir), shell=True)
        check_output('chmod -R a+r {0}'.format(artifact_dir), shell=True)

    request.addfinalizer(module_teardown)


def test_start(module_setup, app, domain, device_host):
    add_host_alias(app, device_host, domain)


def test_login(selenium, device_user, device_password):
    selenium.open_app()
    selenium.find_by(By.ID, "username-textfield").send_keys(device_user)
    password = selenium.find_by(By.ID, "password-textfield")
    password.send_keys(device_password)
    selenium.screenshot('login')
    #password.send_keys(Keys.RETURN)
    selenium.find_by(By.ID, "sign-in-button").click()
    selenium.find_by(By.XPATH, "//div[contains(.,'Connected to')]")
    selenium.screenshot('connected')
    selenium.invisible_by(By.XPATH, "//div[contains(.,'Connected to')]")
    selenium.find_by(By.XPATH, "//p[contains(.,'No active downloads')]")
    selenium.screenshot('no-downloads')


def test_download(selenium, device_user, device_password):
    selenium.click_by(By.XPATH, "//button[@aria-label='Home speed dial']").click()
    selenium.click_by(By.XPATH, "//button[@aria-label='New download']")
    selenium.find_by(By.XPATH, "//textarea").send_keys("https://m.youtube.com/watch?v=x983nr0lXwo")
    selenium.click_by(By.XPATH, "//button[contains(.,'Start')]")
    selenium.find_by(By.XPATH, "//div[contains(.,'Syncloud Introduction')]")
    selenium.find_by(By.XPATH, "//span[contains(.,'Completed')]")
    selenium.screenshot('completed')

def test_teardown(driver):
    driver.quit()

