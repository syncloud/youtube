package main

import (
	"fmt"
	"github.com/spf13/cobra"
	"github.com/syncloud/golib/log"
	"hooks/installer"
	"os"
)

func main() {
	logger := log.Logger()

	var cmd = &cobra.Command{
		Use:          "cli",
		SilenceUsage: true,
	}

	cmd.AddCommand(&cobra.Command{
		Use: "storage-change",
		RunE: func(cmd *cobra.Command, args []string) error {
			logger.Info("storage-change")
			return installer.New().StorageChange()
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "access-change",
		Run: func(cmd *cobra.Command, args []string) {
			logger.Warn("access-change is not implemented yet")
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "backup-pre-stop",
		Run: func(cmd *cobra.Command, args []string) {
			logger.Warn("backup-pre-stop is not implemented yet")
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "restore-pre-start",
		Run: func(cmd *cobra.Command, args []string) {
			logger.Warn("restore-pre-start is not implemented yet")
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "restore-post-start",
		Run: func(cmd *cobra.Command, args []string) {
			logger.Warn("restore-post-start is not implemented yet")
		},
	})

	err := cmd.Execute()
	if err != nil {
		fmt.Print(err)
		os.Exit(1)
	}
}
