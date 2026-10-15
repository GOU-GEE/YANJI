// SPDX-License-Identifier: MPL-2.0
// The embedded node transfers immutable application records, never SQLite files.
package engine

import (
	"context"
	"crypto/tls"
	"encoding/base64"
	"encoding/json"
	"errors"
	"log/slog"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/syncthing/syncthing/lib/build"
	"github.com/syncthing/syncthing/lib/config"
	"github.com/syncthing/syncthing/lib/events"
	"github.com/syncthing/syncthing/lib/locations"
	"github.com/syncthing/syncthing/lib/protocol"
	"github.com/syncthing/syncthing/lib/svcutil"
	"github.com/syncthing/syncthing/lib/syncthing"
)

type peer struct {
	ID          string   `json:"id"`
	Fingerprint string   `json:"fingerprint"`
	Addresses   []string `json:"addresses"`
}
type request struct {
	Command     string `json:"command"`
	Directory   string `json:"directory"`
	FolderPath  string `json:"folder_path"`
	Workspace   string `json:"workspace"`
	Certificate string `json:"certificate"`
	PrivateKey  string `json:"private_key"`
	Peers       []peer `json:"peers"`
	// Only used by isolated integration tests, never enabled by the app.
	LocalOnly bool     `json:"local_only"`
	Listen    []string `json:"listen"`
}
type node struct {
	myID   protocol.DeviceID
	app    *syncthing.App
	cfg    config.Wrapper
	cancel context.CancelFunc
	folder string
	peers  []peer
}

var mu sync.Mutex
var current *node

func deviceID(p peer) (protocol.DeviceID, error) {
	raw, err := base64.StdEncoding.DecodeString(p.Fingerprint)
	if err != nil || len(raw) != 32 {
		return protocol.EmptyDeviceID, errors.New("invalid paired certificate fingerprint")
	}
	var id protocol.DeviceID
	copy(id[:], raw)
	return id, nil
}
func configure(c *config.Configuration, r request, myID protocol.DeviceID) error {
	devices := []config.DeviceConfiguration{{DeviceID: myID, Name: "YanJi", Addresses: []string{"dynamic"}}}
	folders := []config.FolderDeviceConfiguration{{DeviceID: myID}}
	for _, p := range r.Peers {
		id, err := deviceID(p)
		if err != nil {
			return err
		}
		if id == myID {
			continue
		}
		addresses := p.Addresses
		if len(addresses) == 0 {
			addresses = []string{"dynamic"}
		}
		devices = append(devices, config.DeviceConfiguration{DeviceID: id, Name: p.ID, CertName: p.ID, Addresses: addresses, Compression: config.CompressionAlways})
		folders = append(folders, config.FolderDeviceConfiguration{DeviceID: id})
	}
	c.Devices = devices
	f := c.Defaults.Folder.Copy()
	f.ID = "yanji-" + r.Workspace
	f.Label = "YanJi records"
	f.Path = r.FolderPath
	f.Devices = folders
	f.Type = config.FolderTypeSendReceive
	f.IgnorePerms = true
	f.FSWatcherEnabled = false
	f.RescanIntervalS = 10
	f.Versioning = config.VersioningConfiguration{Type: "simple", Params: map[string]string{"keep": "5"}}
	c.Folders = []config.FolderConfiguration{f}
	c.GUI.Enabled = false
	c.Options.CREnabled = false
	c.Options.URAccepted = -1
	c.Options.CRURL = ""
	c.Options.URURL = ""
	c.Options.ReleasesURL = ""
	c.Options.AutoUpgradeIntervalH = 0
	c.Options.RelayReconnectIntervalM = 1
	c.Options.GlobalAnnEnabled = !r.LocalOnly
	c.Options.RelaysEnabled = !r.LocalOnly
	if len(r.Listen) > 0 {
		c.Options.RawListenAddresses = r.Listen
	}
	return nil
}

// Execute is a deliberately small JSON boundary suitable for gomobile and FFI.
// It never exposes private keys, a web administration UI, or arbitrary paths
// from peers. The Flutter application alone controls the shared directory.
func Execute(input string) (string, error) {
	mu.Lock()
	defer mu.Unlock()
	var r request
	if err := json.Unmarshal([]byte(input), &r); err != nil {
		return "", err
	}
	switch r.Command {
	case "start":
		if current != nil {
			return "{}", nil
		}
		if r.Directory == "" || r.Workspace == "" || r.FolderPath == "" {
			return "", errors.New("missing node paths or workspace")
		}
		cert, err := tls.X509KeyPair([]byte(r.Certificate), []byte(r.PrivateKey))
		if err != nil {
			return "", err
		}
		myID := protocol.NewDeviceID(cert.Certificate[0])
		for _, dir := range []string{r.Directory, r.FolderPath, filepath.Join(r.FolderPath, ".stfolder")} {
			if err = os.MkdirAll(dir, 0700); err != nil {
				return "", err
			}
		}
		locations.SetBaseDir(locations.DataBaseDir, r.Directory)
		locations.SetBaseDir(locations.ConfigBaseDir, r.Directory)
		slog.SetDefault(slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelWarn})))
		build.Version = "v2.1.5"
		build.User = "yanji"
		build.Host = "embedded"
		ctx, cancel := context.WithCancel(context.Background())
		logger := events.NewLogger()
		go logger.Serve(ctx)
		c := config.New(myID)
		if err = configure(&c, r, myID); err != nil {
			cancel()
			return "", err
		}
		cfg := config.Wrap(filepath.Join(r.Directory, "config.xml"), c, myID, logger)
		go cfg.Serve(ctx)
		sdb, err := syncthing.OpenDatabase(filepath.Join(r.Directory, "index-v2"), 10920*time.Hour)
		if err != nil {
			cancel()
			return "", err
		}
		app, err := syncthing.New(cfg, sdb, logger, cert, syncthing.Options{NoUpgrade: true})
		if err != nil {
			cancel()
			sdb.Close()
			return "", err
		}
		if err = app.Start(); err != nil {
			cancel()
			return "", err
		}
		current = &node{myID: myID, app: app, cfg: cfg, cancel: cancel, folder: "yanji-" + r.Workspace, peers: r.Peers}
		return "{}", nil
	case "configure":
		if current == nil {
			return "", errors.New("node not started")
		}
		self := current.myID
		updated := current.cfg.RawCopy()
		if err := configure(&updated, r, self); err != nil {
			return "", err
		}
		waiter, err := current.cfg.Modify(func(c *config.Configuration) { *c = updated })
		if err != nil {
			return "", err
		}
		waiter.Wait()
		current.peers = r.Peers
		return "{}", nil
	case "scan":
		if current == nil {
			return "", errors.New("node not started")
		}
		err := current.app.Internals.ScanFolderSubdirs(current.folder, nil)
		if err != nil {
			return "", err
		}
		return "{}", nil
	case "status":
		if current == nil {
			return "{\"connected\":[]}", nil
		}
		connected := []string{}
		for _, p := range current.peers {
			id, err := deviceID(p)
			if err == nil && current.app.Internals.IsConnectedTo(id) {
				connected = append(connected, p.ID)
			}
		}
		result, err := json.Marshal(map[string]any{"connected": connected})
		return string(result), err
	case "stop":
		if current != nil {
			current.app.Stop(svcutil.ExitSuccess)
			current.cancel()
			current = nil
		}
		return "{}", nil
	default:
		return "", errors.New("unsupported node command")
	}
}
