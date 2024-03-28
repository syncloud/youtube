local name = "youtube";
local browser = "firefox";
local version = "latest";
local nginx = "1.24.0";
local authelia = "master";
local selenium = "4.19.0-20240328";
local deployer = "https://github.com/syncloud/store/releases/download/4/syncloud-release";

local build(arch, test_ui, dind) = [{
    kind: "pipeline",
    type: "docker",
    name: arch,
    platform: {
        os: "linux",
        arch: arch
    },
    steps: [
        {
            name: "version",
            image: "debian:buster-slim",
            commands: [
                "echo $DRONE_BUILD_NUMBER > version"
            ]
        },
      {
            name: "nginx",
            image: "docker:" + dind,
                commands: [
                "./nginx/build.sh " + nginx
            ],
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
      {
            name: "authelia",
            image: "docker:" + dind,
            commands: [
                "./authelia/package.sh " + authelia
            ],
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: "webui",
            image: "marcobaobao/yt-dlp-webui:" + version,
            commands: [
                "./webui/build.sh"
            ]
        },

       {
            name: "test webui",
            image: "debian:buster-slim",
            commands: [
                "./webui/test.sh"
            ]
        },
        {
            name: "cli",
            image: "golang:1.20",
            commands: [
                "cd cli",
                "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/meta/hooks/install ./cmd/install",
                "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/meta/hooks/configure ./cmd/configure",
                "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/meta/hooks/pre-refresh ./cmd/pre-refresh",
                "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/meta/hooks/post-refresh ./cmd/post-refresh",
                "go build -ldflags '-linkmode external -extldflags -static' -o ../build/snap/bin/cli ./cmd/cli",
            ]
        },
        {
            name: "package",
            image: "debian:buster-slim",
            commands: [
                "VERSION=$(cat version)",
                "./package.sh " + name + " $VERSION "
            ]
        },
        {
            name: "test-integration",
            image: "python:3.8-slim-buster",
            commands: [
              "APP_ARCHIVE_PATH=$(realpath $(cat package.name))",
              "cd test",
              "./deps.sh",
              "py.test -x -s test.py --distro=buster --domain=buster.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=" + name + ".buster.com --app=" + name + " --arch=" + arch
            ]
        }] + ( if test_ui then [
        {
            name: "selenium-video",
            image: "selenium/video:ffmpeg-4.3.1-20220208",
            detach: true,
            environment: {
                DISPLAY_CONTAINER_NAME: "selenium",
                FILE_NAME: "video.mkv"
            },
            volumes: [
                {
                    name: "shm",
                    path: "/dev/shm"
                },
               {
                    name: "videos",
                    path: "/videos"
                }
            ]
        },
        {
            name: "test-ui",
            image: "python:3.8-slim-buster",
            commands: [
              "cd test",
              "./deps.sh",
              "py.test -x -s ui.py --distro=buster --ui-mode=desktop --domain=buster.com --device-host=" + name + ".buster.com --app=" + name + " --browser-height=2000 --browser=" + browser,
            ],
            volumes: [{
                name: "videos",
                path: "/videos"
            }]
        }

] else [] ) +[
    {
        name: "test-upgrade",
        image: "python:3.8-slim-buster",
        commands: [
          "APP_ARCHIVE_PATH=$(realpath $(cat package.name))",
          "cd test",
          "./deps.sh",
          "py.test -x -s upgrade.py --distro=buster --ui-mode=desktop --domain=buster.com --app-archive-path=$APP_ARCHIVE_PATH --device-host=" + name + ".buster.com --app=" + name + " --browser=" + browser,
        ]
    },
        {
            name: "upload",
        image: "debian:buster-slim",
        environment: {
            AWS_ACCESS_KEY_ID: {
                from_secret: "AWS_ACCESS_KEY_ID"
            },
            AWS_SECRET_ACCESS_KEY: {
                from_secret: "AWS_SECRET_ACCESS_KEY"
            },
                 SYNCLOUD_TOKEN: {
                     from_secret: "SYNCLOUD_TOKEN"
                 }
        },
        commands: [
          "PACKAGE=$(cat package.name)",
          "apt update && apt install -y wget",
          "wget " + deployer + "-" + arch + " -O release --progress=dot:giga",
          "chmod +x release",
          "./release publish -f $PACKAGE -b $DRONE_BRANCH"
         ],
        when: {
            branch: ["stable", "master"],
            event: [ "push" ]
        }
        },
         {
                 name: "promote",
                 image: "debian:buster-slim",
                 environment: {
                     AWS_ACCESS_KEY_ID: {
                         from_secret: "AWS_ACCESS_KEY_ID"
                     },
                     AWS_SECRET_ACCESS_KEY: {
                         from_secret: "AWS_SECRET_ACCESS_KEY"
                     },
                      SYNCLOUD_TOKEN: {
                          from_secret: "SYNCLOUD_TOKEN"
                      }
                 },
                 commands: [
                   "apt update && apt install -y wget",
                   "wget " + deployer + "-" + arch + " -O release --progress=dot:giga",
                   "chmod +x release",
                   "./release promote -n " + name + " -a $(dpkg --print-architecture)"
                 ],
                 when: {
                     branch: ["stable"],
                     event: ["push"]
                 }
           },
        {
            name: "artifact",
            image: "appleboy/drone-scp:1.6.4",
            settings: {
                host: {
                    from_secret: "artifact_host"
                },
                username: "artifact",
                key: {
                    from_secret: "artifact_key"
                },
                timeout: "2m",
                command_timeout: "2m",
                target: "/home/artifact/repo/" + name + "/${DRONE_BUILD_NUMBER}-" + arch,
                source: "artifact/*",
		             strip_components: 1
            },
            when: {
              status: [ "failure", "success" ],
              event: [ "push" ]
            }
        }
    ],
     trigger: {
       event: [
         "push",
         "pull_request"
       ]
     },
    services: [
        {
            name: "docker",
            image: "docker:" + dind,
            privileged: true,
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: name + ".buster.com",
            image: "syncloud/platform-buster-" + arch + ":22.02",
            privileged: true,
            volumes: [
                {
                    name: "dbus",
                    path: "/var/run/dbus"
                },
                {
                    name: "dev",
                    path: "/dev"
                }
            ]
        }
    ] + ( if test_ui then [{
            name: "selenium",
            image: "selenium/standalone-" + browser + ":" + selenium,
            volumes: [{
                name: "shm",
                path: "/dev/shm"
            }]
        }
    ] else [] ),
    volumes: [
        {
            name: "dbus",
            host: {
                path: "/var/run/dbus"
            }
        },
        {
            name: "dev",
            host: {
                path: "/dev"
            }
        },
        {
            name: "shm",
            temp: {}
        },
        {
            name: "dockersock",
            temp: {}
        },
        {
            name: "videos",
            temp: {}
        },
      ]
}];

build("amd64", true, "20.10.21-dind") +
build("arm64", false, "20.10.21-dind") +
build("arm", false, "19.03.8-dind")
