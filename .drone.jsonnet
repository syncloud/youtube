local name = 'youtube';
local version = 'latest';
local nginx = '1.24.0';
local platform = '26.04.10';
local playwright = 'mcr.microsoft.com/playwright:v1.59.1-jammy';
local deployer = 'https://github.com/syncloud/store/releases/download/4/syncloud-release';
local python = '3.12-slim-bookworm';
local distro_default = 'bookworm';
local distros = ['bookworm'];

local build(arch, test_ui, dind) = [{
  kind: 'pipeline',
  type: 'docker',
  name: arch,
  platform: {
    os: 'linux',
    arch: arch,
  },
  steps: [
    {
      name: 'version',
      image: 'debian:bookworm-slim',
      commands: [
        'echo $DRONE_BUILD_NUMBER > version',
      ],
    },
    {
      name: 'nginx',
      image: 'nginx:' + nginx,
      commands: [
        './nginx/build.sh',
      ],
    },
    {
      name: 'nginx test',
      image: 'syncloud/platform-' + distro_default + '-' + arch + ':' + platform,
      commands: [
        './nginx/test.sh',
      ],
    },
    {
      name: 'webui',
      image: 'marcobaobao/yt-dlp-webui:' + version,
      commands: [
        './webui/build.sh',
      ],
    },

    {
      name: 'test webui',
      image: 'syncloud/platform-'+distro_default+'-' + arch + ':' + platform,
      commands: [
        './webui/test.sh',
      ],
    },
    {
      name: 'cli',
      image: 'golang:1.20',
      commands: [
        'cd cli',
        'CGO_ENABLED=0 go build -o ../build/snap/meta/hooks/install ./cmd/install',
        'CGO_ENABLED=0 go build -o ../build/snap/meta/hooks/configure ./cmd/configure',
        'CGO_ENABLED=0 go build -o ../build/snap/meta/hooks/pre-refresh ./cmd/pre-refresh',
        'CGO_ENABLED=0 go build -o ../build/snap/meta/hooks/post-refresh ./cmd/post-refresh',
        'CGO_ENABLED=0 go build -o ../build/snap/bin/cli ./cmd/cli',
      ],
    },
    {
      name: 'package',
      image: 'debian:bookworm-slim',
      commands: [
        'VERSION=$(cat version)',
        './package.sh ' + name + ' $VERSION ',
      ],
    }
    ] + [
      {
        name: 'test ' + distro,
        image: 'python:' + python,
        commands: [
          'APP_ARCHIVE_PATH=$(realpath $(cat package.name))',
          'cd test',
          './deps.sh',
          'py.test -x -s test.py --distro=' + distro + ' --domain=' + distro + '.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=' + name + '.' + distro + '.com --app=' + name + ' --arch=' + arch,
        ],
      }
      for distro in distros
    ] + (if test_ui then [
      {
        name: 'test-ui-' + distro,
        image: playwright,
        environment: {
          PLAYWRIGHT_FULL_DOMAIN: distro + '.com',
          PLAYWRIGHT_APP_DOMAIN: name + '.' + distro + '.com',
          PLAYWRIGHT_DEVICE_HOST: name + '.' + distro + '.com',
          PLAYWRIGHT_DEVICE_USER: 'user',
          PLAYWRIGHT_DEVICE_PASSWORD: 'Password1',
          PLAYWRIGHT_ARTIFACT_DIR: '/drone/src/artifact/e2e-' + distro,
        },
        commands: [
          'apt-get update && apt-get install -y sshpass',
          'cd test/e2e',
          'npm ci',
          'npx playwright test --project=desktop',
        ],
      }
      for distro in distros
    ] else []) + [
    {
      name: 'test-upgrade',
      image: 'python:' + python,
      commands: [
        'APP_ARCHIVE_PATH=$(realpath $(cat package.name))',
        'cd test',
        './deps.sh',
        'py.test -x -s upgrade.py --distro=' + distro_default + ' --domain=' + distro_default + '.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=' + name + '.' + distro_default + '.com --app=' + name,
      ],
    },
    {
      name: 'upload',
      image: 'debian:bookworm-slim',
      environment: {
        AWS_ACCESS_KEY_ID: {
          from_secret: 'AWS_ACCESS_KEY_ID',
        },
        AWS_SECRET_ACCESS_KEY: {
          from_secret: 'AWS_SECRET_ACCESS_KEY',
        },
        SYNCLOUD_TOKEN: {
          from_secret: 'SYNCLOUD_TOKEN',
        },
      },
      commands: [
        'PACKAGE=$(cat package.name)',
        'apt update && apt install -y wget',
        'wget ' + deployer + '-' + arch + ' -O release --progress=dot:giga',
        'chmod +x release',
        './release publish -f $PACKAGE -b $DRONE_BRANCH',
      ],
      when: {
        branch: ['stable', 'master'],
        event: ['push'],
      },
    },
    {
      name: 'promote',
      image: 'debian:bookworm-slim',
      environment: {
        AWS_ACCESS_KEY_ID: {
          from_secret: 'AWS_ACCESS_KEY_ID',
        },
        AWS_SECRET_ACCESS_KEY: {
          from_secret: 'AWS_SECRET_ACCESS_KEY',
        },
        SYNCLOUD_TOKEN: {
          from_secret: 'SYNCLOUD_TOKEN',
        },
      },
      commands: [
        'apt update && apt install -y wget',
        'wget ' + deployer + '-' + arch + ' -O release --progress=dot:giga',
        'chmod +x release',
        './release promote -n ' + name + ' -a $(dpkg --print-architecture)',
      ],
      when: {
        branch: ['stable'],
        event: ['push'],
      },
    },
    {
      name: 'artifact',
      image: 'appleboy/drone-scp:1.6.4',
      settings: {
        host: {
          from_secret: 'artifact_host',
        },
        username: 'artifact',
        key: {
          from_secret: 'artifact_key',
        },
        timeout: '2m',
        command_timeout: '2m',
        target: '/home/artifact/repo/' + name + '/${DRONE_BUILD_NUMBER}-' + arch,
        source: 'artifact/*',
        strip_components: 1,
      },
      when: {
        status: ['failure', 'success'],
        event: ['push'],
      },
    },
  ],
  trigger: {
    event: ['push'],
  },
  services: [
    {
      name: 'docker',
      image: 'docker:' + dind,
      privileged: true,
      volumes: [
        {
          name: 'dockersock',
          path: '/var/run',
        },
      ],
    },
    ] + [
          {
            name: name + '.' + distro + '.com',
            image: 'syncloud/platform-' + distro + '-' + arch + ':' + platform,
            privileged: true,
            entrypoint: ['/bin/sh', '-c', "mkdir -p /etc/systemd/system/snapd.service.d && printf '[Service]\\nExecStartPost=/bin/sh -c \"/usr/bin/snap set system refresh.hold=2099-01-01T00:00:00Z\"\\n' > /etc/systemd/system/snapd.service.d/disable-refresh.conf && exec /sbin/init"],
            volumes: [
              {
                name: 'dbus',
                path: '/var/run/dbus',
              },
              {
                name: 'dev',
                path: '/dev',
              },
            ],
          }
          for distro in distros
        ],
  volumes: [
    {
      name: 'dbus',
      host: {
        path: '/var/run/dbus',
      },
    },
    {
      name: 'dev',
      host: {
        path: '/dev',
      },
    },
    {
      name: 'dockersock',
      temp: {},
    },
  ],
}];

build('amd64', true, '20.10.21-dind') +
build('arm64', false, '20.10.21-dind')
