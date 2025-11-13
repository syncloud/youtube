package installer

import (
	"fmt"
	"os"
	"path"

	cp "github.com/otiai10/copy"
	"github.com/syncloud/golib/config"
	"github.com/syncloud/golib/linux"
	"github.com/syncloud/golib/platform"
	"go.uber.org/zap"
)

const App = "youtube"

type Variables struct {
	App         string
	AppDir      string
	DataDir     string
	CommonDir   string
	AuthUrl     string
	AuthAddress string
}

type Installer struct {
	newVersionFile     string
	currentVersionFile string
	configDir          string
	appDir             string
	dataDir            string
	commonDir          string
	platformClient     *platform.Client
	logger             *zap.Logger
}

func New(logger *zap.Logger) *Installer {
	appDir := fmt.Sprintf("/snap/%s/current", App)
	dataDir := fmt.Sprintf("/var/snap/%s/current", App)
	commonDir := fmt.Sprintf("/var/snap/%s/common", App)

	configDir := path.Join(dataDir, "config")

	return &Installer{
		newVersionFile:     path.Join(appDir, "version"),
		currentVersionFile: path.Join(dataDir, "version"),
		configDir:          configDir,
		appDir:             appDir,
		dataDir:            dataDir,
		commonDir:          commonDir,
		platformClient:     platform.New(),
		logger:             logger,
	}
}

func (i *Installer) Install() error {
	err := linux.CreateUser(App)
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

	err := linux.CreateMissingDirs(
		path.Join(i.dataDir, "nginx"),
	)
	if err != nil {
		return err
	}

	authUrl, err := i.platformClient.GetAppUrl("auth")
	if err != nil {
		return err
	}

	err = config.Generate(
		path.Join(i.appDir, "config"),
		path.Join(i.dataDir, "config"),
		Variables{
			AuthUrl:   authUrl,
			App:       App,
			AppDir:    i.appDir,
			DataDir:   i.dataDir,
			CommonDir: i.commonDir,
		},
	)
	return err
}

func (i *Installer) FixPermissions() error {
	err := linux.Chown(i.dataDir, App)
	if err != nil {
		return err
	}
	err = linux.Chown(i.commonDir, App)
	if err != nil {
		return err
	}
	return nil
}

func (i *Installer) AccessChange() error {
	return i.UpdateConfigs()
}

func (i *Installer) BackupPreStop() error {
	return i.PreRefresh()
}

func (i *Installer) RestorePreStart() error {
	return i.PostRefresh()
}

func (i *Installer) RestorePostStart() error {
	return i.Configure()
}
