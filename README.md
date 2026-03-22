# luci-app-cert-auth

> **Warning:** This package is currently in testing and may still contain bugs. Use at your own risk and make sure you always have SSH access to your router as a fallback.

Client certificate authentication for the LuCI web interface. Allows passwordless login using TLS client certificates verified by nginx.

## Disclaimer
This package is provided "as is", without warranty of any kind, express or implied. The author is not responsible for any damage, data loss, security issues, or other problems that may result from using this package. Use at your own risk! 

## How it works

1. **nginx** verifies the client certificate against a CA certificate (`ssl_verify_client on`) 
2. Without a valid certificate, nginx rejects the connection with `400 Bad Request`
3. With a valid certificate, the CGI script creates a fully privileged LuCI session (identical to a root login) and redirects to the LuCI dashboard — no password required

> **Note:** SSH access is not affected.

## Requirements 

> **Note:** uhttpd does not support TLS client certificate verification. This package requires nginx.
- OpenWrt with **nginx** as webserver (package `luci-nginx`)
- A CA certificate and client certificates (see [Setup](#setup))


## Installation

### From source

```sh
make menuconfig
# Navigate to: LuCI -> Applications -> luci-app-cert-auth
```

## Setup

### 1. Create CA and client certificate

```sh
# Create CA
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/CN=OpenWrt-CA"

# Create client certificate
openssl genrsa -out client.key 4096
openssl req -new -key client.key -out client.csr -subj "/CN=admin"
openssl x509 -req -days 3650 -in client.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out client.crt

# Export as PKCS12 for browser import
openssl pkcs12 -export -out client.p12 -inkey client.key -in client.crt \
  -certfile ca.crt -passout pass:
```

### 2. Import client certificate into your browser

**Chromium-based browsers (Vivaldi, Chrome, Edge) on Linux (I use Vivaldi):**

```sh
sudo apt install libnss3-tools

certutil -d sql:$HOME/.pki/nssdb -A -t "CT,," -n "OpenWrt-CA" -i ca.crt
pk12util -d sql:$HOME/.pki/nssdb -i client.p12 -W ""
```

**Firefox:**

Settings → Privacy & Security → Certificates → View Certificates → Your Certificates → Import → select `client.p12`

### 3. Deploy CA certificate to the router

```sh
scp -O ca.crt root@192.168.1.1:/etc/nginx/conf.d/ca.crt
```

### 4. Enable client certificate verification

```sh
uci set nginx._lan.ssl_client_certificate='/etc/nginx/conf.d/ca.crt'
uci set nginx._lan.ssl_verify_client='on'
uci commit nginx
/etc/init.d/nginx restart
```

> If the CA certificate is already at `/etc/nginx/conf.d/ca.crt`, the UCI defaults script should configure it automatically.

## Usage

Open `https://<router-ip>/cgi-bin/luci-cert-auth` in your browser. You will be prompted to select your client certificate and then redirected to the LuCI dashboard without entering a password.

The regular login at `https://<router-ip>/cgi-bin/luci/` remains available as a fallback.

## Creating additional client certificates

```sh
openssl genrsa -out client2.key 4096
openssl req -new -key client2.key -out client2.csr -subj "/CN=admin2"
openssl x509 -req -days 3650 -in client2.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out client2.crt
openssl pkcs12 -export -out client2.p12 -inkey client2.key -in client2.crt \
  -certfile ca.crt -passout pass:
```

## Uninstall / Rollback

```sh
uci delete nginx._lan.ssl_client_certificate
uci delete nginx._lan.ssl_verify_client
uci commit nginx
rm /www/cgi-bin/luci-cert-auth
rm /etc/nginx/conf.d/luci-cert-auth.locations
/etc/init.d/nginx restart
```

## Technical details

- The nginx location block passes `$ssl_client_verify` as `HTTP_X_SSL_VERIFY` to the CGI script via uwsgi
- The CGI script uses the `luci-webui` uwsgi socket (not `luci-cgi_io`, which restricts execution to `/usr/libexec/cgi-io`)
- ACL groups are read dynamically from `/usr/share/rpcd/acl.d/*.json`, so newly installed LuCI apps are automatically authorized
- A CSRF token is generated and stored in the session (required by LuCI's `session_retrieve`)
- SSH access is not affected by this configuration

## License

Apache-2.0
