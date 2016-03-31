#cloud-config

coreos:
  units:
    - name: fleet.service
      command: start
    - name: rancher.service
      command: start
      content: |
        [Unit]
        Description=Rancher PoC
        After=docker.service
        Requires=docker.service
        
        [Service]
        Restart=always
        EnvironmentFile=/etc/environment
        ExecStartPre=-/usr/bin/env docker kill rancher
        ExecStartPre=-/usr/bin/env docker rm rancher
        ExecStart=/usr/bin/env bash -c '/usr/bin/docker start -a rancher/server || exec docker run --name rancher -p 8080:8080 rancher/server'
        ExecStop=/usr/bin/docker stop rancher
        ExecStop=/usr/bin/docker rm rancher
