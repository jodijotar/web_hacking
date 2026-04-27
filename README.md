<img src="assets/dataflow_graph.png">

## kali linux docker cli first use:
```sh
docker run --network host \
  --cap-add=NET_raw --cap-add=NET_ADMIN \
  --mount type=bind,src=/<host-path>/kali-workspace,dst=/kali-workspace \
  --tty --interactive --name kali-jeyjey \
  kalilinux/kali-rolling
```

```sh
apt update && apt -y install kali-linux-headless
```
