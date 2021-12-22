# k8s-traefik-pebble

Example showing how to use [Pebble](https://github.com/letsencrypt/pebble#readme) as a [Traefik](https://github.com/traefik/traefik#readme) certificate resolver in Kubernetes. The configured resolver is used to obtain an ACME certificate for the domain `whoami.localhost` which resolves to a whoami application exposed through a [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/). 

## Usage

```shell
$ make help

Usage:
  make <target>
  help             Display this help
  start            Start a k3d cluster named test
  stop             Stop the k3d cluster named test
```

## Send a request to the whoami service

```shell
$ curl -vk https://whoami.localhost
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to whoami.localhost (127.0.0.1) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=whoami.localhost
*  start date: Sep 22 19:04:42 2021 GMT
*  expire date: Sep 22 19:04:42 2026 GMT
*  issuer: CN=Pebble Intermediate CA 0ff996
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7f852c80c600)
> GET / HTTP/2
> Host: whoami.localhost
> User-Agent: curl/7.64.1
> Accept: */*
>
* Connection state changed (MAX_CONCURRENT_STREAMS == 250)!
< HTTP/2 200
< content-type: text/plain; charset=utf-8
< date: Wed, 22 Sep 2021 20:05:51 GMT
< content-length: 412
<
Hostname: whoami-76c64d4749-dvrkj
IP: 127.0.0.1
IP: ::1
IP: 10.42.0.5
IP: fe80::5090:38ff:fe60:3dde
RemoteAddr: 10.42.1.4:46198
GET / HTTP/1.1
Host: whoami.localhost
User-Agent: curl/7.64.1
Accept: */*
Accept-Encoding: gzip
X-Forwarded-For: 10.42.0.0
X-Forwarded-Host: whoami.localhost
X-Forwarded-Port: 443
X-Forwarded-Proto: https
X-Forwarded-Server: traefik-674b58b48f-rlbxh
X-Real-Ip: 10.42.0.0

* Connection #0 to host whoami.localhost left intact
* Closing connection 0 
```

## Persisting the ACME certificates

The [ACME storage](https://doc.traefik.io/traefik/v2.5/https/acme/#storage) stores the certificates to avoid re-asking them at each Traefik deployment update.

In order to persist it, Kubernetes provides [Persistent Volume Claims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).
The k3d `local-path` storage class is used in this example, please check the available storage classes in your cluster.

To test that Traefik does not need to ask the certificate anymore, one may start the cluster, and check the Traefik logs:

```shell
$ kubectl -n traefik logs deployment/traefik | grep ACME
```

The following message should appear:

```shell
$ Domains [\"whoami.localhost\"] need ACME certificates generation for domains \"whoami.localhost\"."
```

Now, the following command could be used to force a deployment update:

```shell
$ kubectl -n traefik rollout restart deployment/traefik
```

Now, let's check the Traefik logs:

```shell
$ kubectl -n traefik logs deployment/traefik | grep ACME
time="2021-09-23T08:45:09Z" level=debug msg="No ACME certificate generation required for domains [\"whoami.localhost\"]." rule="Host(`whoami.localhost`) && PathPrefix(`/`)" providerName=pebble.acme routerName=whoami-default-whoami-localhost@kubernetes
```

Et voila, Traefik does not need to re-ask the certificates anymore at each deployment. 
