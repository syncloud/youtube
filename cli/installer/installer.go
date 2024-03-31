package installer

import (
	"fmt"
	"github.com/google/uuid"
	cp "github.com/otiai10/copy"
	"github.com/syncloud/golib/linux"
	"github.com/syncloud/golib/platform"
	"os"
	"path"
	"strings"
)

const (
	App       = "youtube"
	AppDir    = "/snap/youtube/current"
	DataDir   = "/var/snap/youtube/current"
	CommonDir = "/var/snap/youtube/common"
)

type Installer struct {
	newVersionFile                   string
	currentVersionFile               string
	configDir                        string
	platformClient                   *platform.Client
	autheliaStorageEncryptionKeyFile string
	autheliaJwtSecretFile            string
}

func New() *Installer {
	configDir := path.Join(DataDir, "config")

	return &Installer{
		newVersionFile:                   path.Join(AppDir, "version"),
		currentVersionFile:               path.Join(DataDir, "version"),
		configDir:                        configDir,
		platformClient:                   platform.New(),
		autheliaStorageEncryptionKeyFile: path.Join(DataDir, "authelia.storage.encryption.key"),
		autheliaJwtSecretFile:            path.Join(DataDir, "authelia.jwt.secret"),
	}
}

func (i *Installer) Install() error {
	err := linux.CreateUser(App)
	if err != nil {
		return err
	}

	err = os.Mkdir(path.Join(DataDir, "nginx"), 0755)
	if err != nil {
		return err
	}

	err = os.WriteFile(i.autheliaStorageEncryptionKeyFile, []byte(uuid.New().String()), 0644)
	if err != nil {
		return err
	}

	err = os.WriteFile(i.autheliaJwtSecretFile, []byte(uuid.New().String()), 0644)
	if err != nil {
		return err
	}

	err = i.UpdateConfigs()
	if err != nil {
		return err
	}

	err = i.FixPermissions()
	if err != nil {
		return err
	}

	err = i.StorageChange()
	if err != nil {
		return err
	}
	return nil
}

func (i *Installer) Configure() error {
	return i.UpdateVersion()
}

func (i *Installer) PreRefresh() error {
	return nil
}

func (i *Installer) PostRefresh() error {
	err := i.UpdateConfigs()
	if err != nil {
		return err
	}

	err = i.ClearVersion()
	if err != nil {
		return err
	}

	err = i.FixPermissions()
	if err != nil {
		return err
	}
	return nil

}
func (i *Installer) StorageChange() error {
	storageDir, err := i.platformClient.InitStorage(App, App)
	if err != nil {
		return err
	}

	err = os.Mkdir(path.Join(storageDir, "media"), 0755)
	if err != nil {
		if !os.IsExist(err) {
			return err
		}
	}
	err = os.Mkdir(path.Join(storageDir, "cache"), 0755)
	if err != nil {
		if !os.IsExist(err) {
			return err
		}
	}
	err = linux.Chown(storageDir, App)
	if err != nil {
		return err
	}

	return nil
}

func (i *Installer) ClearVersion() error {
	return os.RemoveAll(i.currentVersionFile)
}

func (i *Installer) UpdateVersion() error {
	return cp.Copy(i.newVersionFile, i.currentVersionFile)
}

func (i *Installer) UpdateConfigs() error {

	err := cp.Copy(path.Join(AppDir, "config"), path.Join(DataDir, "config"))
	if err != nil {
		return err
	}

	domain, err := i.platformClient.GetAppDomainName(App)
	if err != nil {
		return err
	}
	appUrl, err := i.platformClient.GetAppDomainName(App)
	if err != nil {
		return err
	}
	encryptionKey, err := os.ReadFile(i.autheliaStorageEncryptionKeyFile)
	if err != nil {
		return err
	}
	jwtSecret, err := os.ReadFile(i.autheliaJwtSecretFile)
	if err != nil {
		return err
	}
	vars := map[string]string{
		"domain":         domain,
		"app_url":        appUrl,
		"encryption_key": string(encryptionKey),
		"jwt_secret":     string(jwtSecret),
	}

	err = i.InjectVariables(
		path.Join(AppDir, "config", "authelia", "config.yml"),
		path.Join(DataDir, "config", "authelia", "config.yml"),
		vars,
	)
	if err != nil {
		return err
	}
	err = i.InjectVariables(
		path.Join(AppDir, "config", "authelia", "authrequest.conf"),
		path.Join(DataDir, "config", "authelia", "authrequest.conf"),
		vars,
	)

	return err

}

func (i *Installer) InjectVariables(from, to string, vars map[string]string) error {
	templateFile, err := os.ReadFile(from)
	if err != nil {
		return err
	}
	template := string(templateFile)
	for key, value := range vars {
		template = strings.ReplaceAll(template, fmt.Sprintf("{{ %s }}", key), value)
	}
	return os.WriteFile(to, []byte(template), 0644)
}

func (i *Installer) FixPermissions() error {
	err := linux.Chown(DataDir, App)
	if err != nil {
		return err
	}
	err = linux.Chown(CommonDir, App)
	if err != nil {
		return err
	}
	return nil
}
