include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-cert-auth
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_LICENSE:=Apache-2.0

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-cert-auth
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI Client Certificate Authentication
  DEPENDS:=+nginx-mod-luci +uwsgi-luci-support
  PKGARCH:=all
endef

define Package/luci-app-cert-auth/description
  Enables certificate-based authentication for the LuCI web interface
  without password. Requires nginx with SSL client certificate verification.
endef

define Build/Compile
endef

define Package/luci-app-cert-auth/install
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(INSTALL_BIN) ./root/www/cgi-bin/luci-cert-auth $(1)/www/cgi-bin/
	$(INSTALL_DIR) $(1)/etc/nginx/conf.d
	$(INSTALL_DATA) ./root/etc/nginx/conf.d/luci-cert-auth.locations $(1)/etc/nginx/conf.d/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./root/etc/uci-defaults/70_luci-cert-auth $(1)/etc/uci-defaults/
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-cert-auth.json $(1)/usr/share/rpcd/acl.d/
endef

$(eval $(call BuildPackage,luci-app-cert-auth))
