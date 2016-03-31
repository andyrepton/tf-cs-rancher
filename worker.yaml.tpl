#cloud-config

coreos:
  units:
    - name: fleet.service
      command: start
