#!/usr/bin/env python3
"""Generate Xcode project for OpenCode Usage (MenuBar + WidgetKit)."""

import hashlib
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.join(SCRIPT_DIR, "..", "OpenCodeUsage.xcodeproj")
PBXPROJ = os.path.join(PROJECT_DIR, "project.pbxproj")

def U(s):
    h = hashlib.md5(s.encode()).hexdigest()[:24].upper()
    return h[:8] + h[8:12] + h[12:16] + h[16:20] + h[20:]

keys = [k for k in """
APP_SRC_BF PROV_BF VIEWS_BF BUNDLE_BF EMBED_BF FETCHER_BF HELPER_BF HELPER_W_BF ICON_BF
APP_PROD WIDGET_PROD APP_SRC APP_INFO APP_ENT FETCHER_SRC HELPER_SRC ICON_FILE
PROV_SRC VIEWS_SRC BUNDLE_SRC WIDGET_INFO WIDGET_ENT
MAIN_GROUP APP_GROUP WIDGET_GROUP SHARED_GROUP PRODUCTS_GROUP
APP_TGT WIDGET_TGT APP_SRC_PHASE WIDGET_SRC_PHASE APP_RES_PHASE
APP_FW_PHASE WIDGET_FW_PHASE APP_EMBED_PHASE
PROJ_ROOT PROJ_CFGLIST APP_CFGLIST WIDGET_CFGLIST
PROJ_DBG PROJ_REL APP_DBG APP_REL WIDGET_DBG WIDGET_REL
""".split() if k]

uuids = {k: U(k) for k in keys}
u = uuids

TEMPLATE = """// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		{APP_SRC_BF} /* OpenCodeUsageBar.swift */ = {isa = PBXBuildFile; fileRef = {APP_SRC}; };
		{FETCHER_BF} /* UsageFetcher.swift */ = {isa = PBXBuildFile; fileRef = {FETCHER_SRC}; };
		{HELPER_BF} /* AppGroupHelper.swift */ = {isa = PBXBuildFile; fileRef = {HELPER_SRC}; };
		{HELPER_W_BF} /* AppGroupHelper.swift in Widget */ = {isa = PBXBuildFile; fileRef = {HELPER_SRC}; };
		{PROV_BF} /* Provider.swift */ = {isa = PBXBuildFile; fileRef = {PROV_SRC}; };
		{VIEWS_BF} /* WidgetViews.swift */ = {isa = PBXBuildFile; fileRef = {VIEWS_SRC}; };
		{BUNDLE_BF} /* WidgetBundle.swift */ = {isa = PBXBuildFile; fileRef = {BUNDLE_SRC}; };
		{ICON_BF} /* AppIcon.icns */ = {isa = PBXBuildFile; fileRef = {ICON_FILE}; };
		{EMBED_BF} /* Widget in Embed */ = {isa = PBXBuildFile; fileRef = {WIDGET_PROD}; settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		{APP_PROD} /* OpenCode Usage.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "OpenCode Usage.app"; sourceTree = BUILT_PRODUCTS_DIR; };
		{WIDGET_PROD} /* OpenCodeWidgetExtension.appex */ = {isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = OpenCodeWidgetExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; };
		{APP_SRC} /* OpenCodeUsageBar.swift */ = {isa = PBXFileReference; path = App/OpenCodeUsageBar.swift; sourceTree = "<group>"; };
		{APP_INFO} /* Info.plist */ = {isa = PBXFileReference; path = App/Info.plist; sourceTree = "<group>"; };
		{APP_ENT} /* App.entitlements */ = {isa = PBXFileReference; path = App/App.entitlements; sourceTree = "<group>"; };
		{FETCHER_SRC} /* UsageFetcher.swift */ = {isa = PBXFileReference; path = Shared/UsageFetcher.swift; sourceTree = "<group>"; };
		{HELPER_SRC} /* AppGroupHelper.swift */ = {isa = PBXFileReference; path = Shared/AppGroupHelper.swift; sourceTree = "<group>"; };
		{ICON_FILE} /* AppIcon.icns */ = {isa = PBXFileReference; lastKnownFileType = image.icns; path = App/AppIcon.icns; sourceTree = "<group>"; };
		{PROV_SRC} /* Provider.swift */ = {isa = PBXFileReference; path = WidgetExtension/Provider.swift; sourceTree = "<group>"; };
		{VIEWS_SRC} /* WidgetViews.swift */ = {isa = PBXFileReference; path = WidgetExtension/WidgetViews.swift; sourceTree = "<group>"; };
		{BUNDLE_SRC} /* WidgetBundle.swift */ = {isa = PBXFileReference; path = WidgetExtension/WidgetBundle.swift; sourceTree = "<group>"; };
		{WIDGET_INFO} /* Info.plist */ = {isa = PBXFileReference; path = WidgetExtension/Info.plist; sourceTree = "<group>"; };
		{WIDGET_ENT} /* Widget.entitlements */ = {isa = PBXFileReference; path = WidgetExtension/Widget.entitlements; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXGroup section */
		{MAIN_GROUP} = {isa = PBXGroup; children = ({APP_GROUP}, {WIDGET_GROUP}, {SHARED_GROUP}, {PRODUCTS_GROUP}); sourceTree = "<group>"; };
		{APP_GROUP} = {isa = PBXGroup; children = ({APP_SRC}, {APP_INFO}, {APP_ENT}, {ICON_FILE}); sourceTree = "<group>"; };
		{WIDGET_GROUP} = {isa = PBXGroup; children = ({PROV_SRC}, {VIEWS_SRC}, {BUNDLE_SRC}, {WIDGET_INFO}, {WIDGET_ENT}); sourceTree = "<group>"; };
		{SHARED_GROUP} = {isa = PBXGroup; children = ({FETCHER_SRC}, {HELPER_SRC}); sourceTree = "<group>"; };
		{PRODUCTS_GROUP} = {isa = PBXGroup; children = ({APP_PROD}, {WIDGET_PROD}); name = Products; sourceTree = "<group>"; };
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{APP_TGT} = {isa = PBXNativeTarget; buildConfigurationList = {APP_CFGLIST}; buildPhases = ({APP_SRC_PHASE}, {APP_FW_PHASE}, {APP_RES_PHASE}, {APP_EMBED_PHASE}); buildRules = (); dependencies = (); name = "OpenCode Usage"; productName = "OpenCode Usage"; productReference = {APP_PROD}; productType = "com.apple.product-type.application"; };
		{WIDGET_TGT} = {isa = PBXNativeTarget; buildConfigurationList = {WIDGET_CFGLIST}; buildPhases = ({WIDGET_SRC_PHASE}, {WIDGET_FW_PHASE}); buildRules = (); dependencies = (); name = OpenCodeWidgetExtension; productName = OpenCodeWidgetExtension; productReference = {WIDGET_PROD}; productType = "com.apple.product-type.app-extension"; };
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{PROJ_ROOT} = {isa = PBXProject; attributes = {BuildIndependentTargetsInParallel = YES; LastSwiftUpdateCheck = 1600; LastUpgradeCheck = 1600; }; buildConfigurationList = {PROJ_CFGLIST}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {MAIN_GROUP}; productRefGroup = {PRODUCTS_GROUP}; projectDirPath = ""; projectRoot = ""; targets = ({APP_TGT}, {WIDGET_TGT}); };
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{APP_RES_PHASE} = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({ICON_BF}); runOnlyForDeploymentPostprocessing = 0; };
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{APP_SRC_PHASE} = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({APP_SRC_BF}, {FETCHER_BF}, {HELPER_BF}); runOnlyForDeploymentPostprocessing = 0; };
		{WIDGET_SRC_PHASE} = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({PROV_BF}, {VIEWS_BF}, {BUNDLE_BF}, {HELPER_W_BF}); runOnlyForDeploymentPostprocessing = 0; };
/* End PBXSourcesBuildPhase section */

/* Begin PBXFrameworksBuildPhase section */
		{APP_FW_PHASE} = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
		{WIDGET_FW_PHASE} = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
/* End PBXFrameworksBuildPhase section */

/* Begin PBXCopyFilesBuildPhase section */
		{APP_EMBED_PHASE} = {isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = ({EMBED_BF}); runOnlyForDeploymentPostprocessing = 0; };
/* End PBXCopyFilesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{PROJ_DBG} = {isa = XCBuildConfiguration; buildSettings = {ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ANALYZER_NONNULL = YES; CLANG_CXX_LANGUAGE_STANDARD = "gnu++20"; CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; COPY_PHASE_STRIP = NO; DEBUG_INFORMATION_FORMAT = dwarf; ENABLE_STRICT_OBJC_MSGSEND = YES; ENABLE_TESTABILITY = YES; GCC_DYNAMIC_NO_PIC = NO; GCC_OPTIMIZATION_LEVEL = 0; GCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)"); MACOSX_DEPLOYMENT_TARGET = 14.0; MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE; ONLY_ACTIVE_ARCH = YES; SDKROOT = macosx; SWIFT_ACTIVE_COMPILATION_CONDITIONS = (DEBUG, "$(inherited)"); SWIFT_OPTIMIZATION_LEVEL = "-Onone"; SWIFT_VERSION = 5.0; }; name = Debug; };
		{PROJ_REL} = {isa = XCBuildConfiguration; buildSettings = {ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ANALYZER_NONNULL = YES; CLANG_CXX_LANGUAGE_STANDARD = "gnu++20"; CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; COPY_PHASE_STRIP = NO; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"; ENABLE_NS_ASSERTIONS = NO; ENABLE_STRICT_OBJC_MSGSEND = YES; GCC_OPTIMIZATION_LEVEL = s; MACOSX_DEPLOYMENT_TARGET = 14.0; MTL_ENABLE_DEBUG_INFO = NO; SDKROOT = macosx; SWIFT_COMPILATION_MODE = wholemodule; SWIFT_OPTIMIZATION_LEVEL = "-O"; SWIFT_VERSION = 5.0; }; name = Release; };
		{APP_DBG} = {isa = XCBuildConfiguration; buildSettings = {ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES; CLANG_ENABLE_MODULES = YES; CODE_SIGN_ENTITLEMENTS = App/App.entitlements; CODE_SIGN_STYLE = Automatic; INFOPLIST_FILE = App/Info.plist; MACOSX_DEPLOYMENT_TARGET = 14.0; PRODUCT_BUNDLE_IDENTIFIER = com.flywinter.opencode-usage-bar; PRODUCT_NAME = "$(TARGET_NAME)"; SDKROOT = macosx; SWIFT_OPTIMIZATION_LEVEL = "-Onone"; SWIFT_VERSION = 5.0; }; name = Debug; };
		{APP_REL} = {isa = XCBuildConfiguration; buildSettings = {ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES; CLANG_ENABLE_MODULES = YES; CODE_SIGN_ENTITLEMENTS = App/App.entitlements; CODE_SIGN_STYLE = Automatic; INFOPLIST_FILE = App/Info.plist; MACOSX_DEPLOYMENT_TARGET = 14.0; PRODUCT_BUNDLE_IDENTIFIER = com.flywinter.opencode-usage-bar; PRODUCT_NAME = "$(TARGET_NAME)"; SDKROOT = macosx; SWIFT_VERSION = 5.0; }; name = Release; };
		{WIDGET_DBG} = {isa = XCBuildConfiguration; buildSettings = {ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES; CLANG_ENABLE_MODULES = YES; CODE_SIGN_ENTITLEMENTS = WidgetExtension/Widget.entitlements; CODE_SIGN_STYLE = Automatic; INFOPLIST_FILE = WidgetExtension/Info.plist; MACOSX_DEPLOYMENT_TARGET = 14.0; PRODUCT_BUNDLE_IDENTIFIER = com.flywinter.opencode-usage-bar.widget; PRODUCT_NAME = "$(TARGET_NAME)"; SDKROOT = macosx; SWIFT_OPTIMIZATION_LEVEL = "-Onone"; SWIFT_VERSION = 5.0; }; name = Debug; };
		{WIDGET_REL} = {isa = XCBuildConfiguration; buildSettings = {ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES; CLANG_ENABLE_MODULES = YES; CODE_SIGN_ENTITLEMENTS = WidgetExtension/Widget.entitlements; CODE_SIGN_STYLE = Automatic; INFOPLIST_FILE = WidgetExtension/Info.plist; MACOSX_DEPLOYMENT_TARGET = 14.0; PRODUCT_BUNDLE_IDENTIFIER = com.flywinter.opencode-usage-bar.widget; PRODUCT_NAME = "$(TARGET_NAME)"; SDKROOT = macosx; SWIFT_VERSION = 5.0; }; name = Release; };
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{PROJ_CFGLIST} = {isa = XCConfigurationList; buildConfigurations = ({PROJ_DBG}, {PROJ_REL}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
		{APP_CFGLIST} = {isa = XCConfigurationList; buildConfigurations = ({APP_DBG}, {APP_REL}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
		{WIDGET_CFGLIST} = {isa = XCConfigurationList; buildConfigurations = ({WIDGET_DBG}, {WIDGET_REL}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
/* End XCConfigurationList section */
	};
	rootObject = {PROJ_ROOT};
}
"""

content = TEMPLATE
for k, v in uuids.items():
    content = content.replace("{" + k + "}", v)

os.makedirs(PROJECT_DIR, exist_ok=True)
with open(PBXPROJ, 'w') as f:
    f.write(content)

print(f"Generated: {PBXPROJ}")
