#!/usr/bin/env python3
"""Generate a single-target Zest.xcodeproj (app only) for easy double-click open."""
import os

ROOT = os.path.dirname(os.path.abspath(__file__))
PROJ_DIR = os.path.join(ROOT, "Zest.xcodeproj")

SOURCES = [
    "Shared/Models/WidgetHeadline.swift",
    "Shared/Store/AppGroup.swift",
    "Shared/Store/SharedStore.swift",
    "Zest/App/ZestApp.swift",
    "Zest/Engine/FeedRanker.swift",
    "Zest/Engine/InteractionEvent.swift",
    "Zest/Engine/InterestProfile.swift",
    "Zest/Engine/InterestStore.swift",
    "Zest/Models/Article.swift",
    "Zest/Models/NewsSource.swift",
    "Zest/Services/FeedCatalog.swift",
    "Zest/Services/NewsAPIClient.swift",
    "Zest/Services/RSSClient.swift",
    "Zest/Services/RSSParser.swift",
    "Zest/Services/SourceSettings.swift",
    "Zest/Services/ThemeSettings.swift",
    "Zest/Services/AdConfig.swift",
    "Zest/Services/NativeAdLoader.swift",
    "Zest/ViewModels/FeedViewModel.swift",
    "Zest/ViewModels/OnboardingViewModel.swift",
    "Zest/Views/FeedView.swift",
    "Zest/Views/FlavourPickerView.swift",
    "Zest/Views/NativeAdCardView.swift",
    "Zest/Views/InterestsView.swift",
    "Zest/Views/OnboardingView.swift",
    "Zest/Views/RootView.swift",
    "Zest/Views/SafariView.swift",
    "Zest/Views/SettingsView.swift",
    "Zest/Views/SourceBadge.swift",
    "Zest/Views/SwipeCardView.swift",
    "Zest/Views/TopicsView.swift",
]
RESOURCES = ["Zest/Assets.xcassets", "Zest/App/PrivacyInfo.xcprivacy", "Zest/Resources/Readability.js"]
INFO_PLIST = "Zest/App/Info.plist"

_counter = 0
def gid():
    global _counter
    _counter += 1
    return format(_counter, "024X")

def ftype(path):
    if path.endswith(".swift"): return "sourcecode.swift"
    if path.endswith(".xcassets"): return "folder.assetcatalog"
    if path.endswith(".xcprivacy"): return "text.plist.xml"
    if path.endswith(".plist"): return "text.plist.xml"
    if path.endswith(".js"): return "sourcecode.javascript"
    return "text"

# Allocate IDs
src = [{"path": p, "ref": gid(), "bf": gid()} for p in SOURCES]
res = [{"path": p, "ref": gid(), "bf": gid()} for p in RESOURCES]
info_ref = gid()
product_ref = gid()

main_group = gid(); src_group = gid(); products_group = gid()
sources_phase = gid(); frameworks_phase = gid(); resources_phase = gid()
target = gid(); project = gid()
proj_cfg_list = gid(); tgt_cfg_list = gid()
proj_debug = gid(); proj_release = gid(); tgt_debug = gid(); tgt_release = gid()
pkg_ref = gid(); prod_dep = gid(); ads_bf = gid()   # Google Mobile Ads SPM

def name(path): return os.path.basename(path)

L = []
A = L.append
A("// !$*UTF8*$!")
A("{")
A("\tarchiveVersion = 1;")
A("\tclasses = {")
A("\t};")
A("\tobjectVersion = 56;")
A("\tobjects = {")

# PBXBuildFile
A("\n/* Begin PBXBuildFile section */")
for f in src:
    A('\t\t%s /* %s in Sources */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };'
      % (f["bf"], name(f["path"]), f["ref"], name(f["path"])))
for f in res:
    A('\t\t%s /* %s in Resources */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };'
      % (f["bf"], name(f["path"]), f["ref"], name(f["path"])))
A('\t\t%s /* GoogleMobileAds in Frameworks */ = {isa = PBXBuildFile; productRef = %s /* GoogleMobileAds */; };'
  % (ads_bf, prod_dep))
A("/* End PBXBuildFile section */")

# PBXFileReference
A("\n/* Begin PBXFileReference section */")
for f in src + res:
    A('\t\t%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = %s; name = "%s"; path = "%s"; sourceTree = SOURCE_ROOT; };'
      % (f["ref"], name(f["path"]), ftype(f["path"]), name(f["path"]), f["path"]))
A('\t\t%s /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; name = "Info.plist"; path = "%s"; sourceTree = SOURCE_ROOT; };'
  % (info_ref, INFO_PLIST))
A('\t\t%s /* Zest.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Zest.app; sourceTree = BUILT_PRODUCTS_DIR; };'
  % product_ref)
A("/* End PBXFileReference section */")

# PBXFrameworksBuildPhase
A("\n/* Begin PBXFrameworksBuildPhase section */")
A("\t\t%s /* Frameworks */ = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (" % frameworks_phase)
A("\t\t\t%s /* GoogleMobileAds in Frameworks */," % ads_bf)
A("\t\t); runOnlyForDeploymentPostprocessing = 0; };")
A("/* End PBXFrameworksBuildPhase section */")

# PBXGroup
A("\n/* Begin PBXGroup section */")
A("\t\t%s = {isa = PBXGroup; children = (" % main_group)
A("\t\t\t%s /* Zest */," % src_group)
A("\t\t\t%s /* Products */," % products_group)
A("\t\t); sourceTree = \"<group>\"; };")
A("\t\t%s /* Zest */ = {isa = PBXGroup; children = (" % src_group)
for f in src + res:
    A("\t\t\t%s /* %s */," % (f["ref"], name(f["path"])))
A("\t\t\t%s /* Info.plist */," % info_ref)
A("\t\t); name = Zest; sourceTree = \"<group>\"; };")
A("\t\t%s /* Products */ = {isa = PBXGroup; children = (" % products_group)
A("\t\t\t%s /* Zest.app */," % product_ref)
A("\t\t); name = Products; sourceTree = \"<group>\"; };")
A("/* End PBXGroup section */")

# PBXNativeTarget
A("\n/* Begin PBXNativeTarget section */")
A("\t\t%s /* Zest */ = {isa = PBXNativeTarget; buildConfigurationList = %s /* Build configuration list for PBXNativeTarget \"Zest\" */; buildPhases = (" % (target, tgt_cfg_list))
A("\t\t\t%s /* Sources */," % sources_phase)
A("\t\t\t%s /* Frameworks */," % frameworks_phase)
A("\t\t\t%s /* Resources */," % resources_phase)
A("\t\t); buildRules = (); dependencies = (); name = Zest; packageProductDependencies = (%s /* GoogleMobileAds */, ); productName = Zest; productReference = %s /* Zest.app */; productType = \"com.apple.product-type.application\"; };" % (prod_dep, product_ref))
A("/* End PBXNativeTarget section */")

# PBXProject
A("\n/* Begin PBXProject section */")
A("\t\t%s /* Project object */ = {isa = PBXProject; attributes = {BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1520; LastUpgradeCheck = 1520; TargetAttributes = {%s = {CreatedOnToolsVersion = 15.2;};};}; buildConfigurationList = %s /* Build configuration list for PBXProject \"Zest\" */; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = %s; productRefGroup = %s /* Products */; projectDirPath = \"\"; projectRoot = \"\"; packageReferences = (%s /* XCRemoteSwiftPackageReference \"swift-package-manager-google-mobile-ads\" */, ); targets = (%s /* Zest */); };"
  % (project, target, proj_cfg_list, main_group, products_group, pkg_ref, target))
A("/* End PBXProject section */")

# PBXResourcesBuildPhase
A("\n/* Begin PBXResourcesBuildPhase section */")
A("\t\t%s /* Resources */ = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (" % resources_phase)
for f in res:
    A("\t\t\t%s /* %s in Resources */," % (f["bf"], name(f["path"])))
A("\t\t); runOnlyForDeploymentPostprocessing = 0; };")
A("/* End PBXResourcesBuildPhase section */")

# PBXSourcesBuildPhase
A("\n/* Begin PBXSourcesBuildPhase section */")
A("\t\t%s /* Sources */ = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (" % sources_phase)
for f in src:
    A("\t\t\t%s /* %s in Sources */," % (f["bf"], name(f["path"])))
A("\t\t); runOnlyForDeploymentPostprocessing = 0; };")
A("/* End PBXSourcesBuildPhase section */")

# Build settings
COMMON_PROJECT = """\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_COMMA = YES;
\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;
\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;
\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;
\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;
\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;
\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;
\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;
\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;
\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;
\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;
\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;
\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;"""

TARGET_COMMON = """\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = "Zest/App/Zest.entitlements";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 16;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "Zest/App/Info.plist";
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.hjatte.zest;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";"""

A("\n/* Begin XCBuildConfiguration section */")
# Project Debug
A("\t\t%s /* Debug */ = {isa = XCBuildConfiguration; buildSettings = {" % proj_debug)
A(COMMON_PROJECT)
A("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
A("\t\t\t\tENABLE_TESTABILITY = YES;")
A("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
A("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
A('\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = ("DEBUG=1", "$(inherited)");')
A("\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;")
A("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
A("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = \"DEBUG $(inherited)\";")
A("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
A("\t\t\t}; name = Debug; };")
# Project Release
A("\t\t%s /* Release */ = {isa = XCBuildConfiguration; buildSettings = {" % proj_release)
A(COMMON_PROJECT)
A("\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";")
A("\t\t\t\tENABLE_NS_ASSERTIONS = NO;")
A("\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;")
A("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
A("\t\t\t\tVALIDATE_PRODUCT = YES;")
A("\t\t\t}; name = Release; };")
# Target Debug
A("\t\t%s /* Debug */ = {isa = XCBuildConfiguration; buildSettings = {" % tgt_debug)
A(TARGET_COMMON)
A("\t\t\t}; name = Debug; };")
# Target Release
A("\t\t%s /* Release */ = {isa = XCBuildConfiguration; buildSettings = {" % tgt_release)
A(TARGET_COMMON)
A("\t\t\t}; name = Release; };")
A("/* End XCBuildConfiguration section */")

# XCConfigurationList
A("\n/* Begin XCConfigurationList section */")
A("\t\t%s /* Build configuration list for PBXProject \"Zest\" */ = {isa = XCConfigurationList; buildConfigurations = (" % proj_cfg_list)
A("\t\t\t%s /* Debug */," % proj_debug)
A("\t\t\t%s /* Release */," % proj_release)
A("\t\t); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };")
A("\t\t%s /* Build configuration list for PBXNativeTarget \"Zest\" */ = {isa = XCConfigurationList; buildConfigurations = (" % tgt_cfg_list)
A("\t\t\t%s /* Debug */," % tgt_debug)
A("\t\t\t%s /* Release */," % tgt_release)
A("\t\t); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };")
A("/* End XCConfigurationList section */")

# Swift Package Manager: Google Mobile Ads (pinned to exact 11.13.0 — GAD API)
A("\n/* Begin XCRemoteSwiftPackageReference section */")
A('\t\t%s /* XCRemoteSwiftPackageReference "swift-package-manager-google-mobile-ads" */ = {isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/googleads/swift-package-manager-google-mobile-ads.git"; requirement = {kind = exactVersion; version = 11.13.0; }; };' % pkg_ref)
A("/* End XCRemoteSwiftPackageReference section */")

A("\n/* Begin XCSwiftPackageProductDependency section */")
A('\t\t%s /* GoogleMobileAds */ = {isa = XCSwiftPackageProductDependency; package = %s /* XCRemoteSwiftPackageReference "swift-package-manager-google-mobile-ads" */; productName = GoogleMobileAds; };' % (prod_dep, pkg_ref))
A("/* End XCSwiftPackageProductDependency section */")

A("\t};")
A("\trootObject = %s /* Project object */;" % project)
A("}")

os.makedirs(PROJ_DIR, exist_ok=True)
with open(os.path.join(PROJ_DIR, "project.pbxproj"), "w") as fh:
    fh.write("\n".join(L) + "\n")

# workspace data
ws_dir = os.path.join(PROJ_DIR, "project.xcworkspace")
os.makedirs(ws_dir, exist_ok=True)
with open(os.path.join(ws_dir, "contents.xcworkspacedata"), "w") as fh:
    fh.write('<?xml version="1.0" encoding="UTF-8"?>\n<Workspace\n   version = "1.0">\n   <FileRef\n      location = "self:">\n   </FileRef>\n</Workspace>\n')

# Pin the Swift package versions so Xcode resolves deterministically.
swiftpm_dir = os.path.join(ws_dir, "xcshareddata", "swiftpm")
os.makedirs(swiftpm_dir, exist_ok=True)
package_resolved = '''{
  "pins" : [
    {
      "identity" : "swift-package-manager-google-mobile-ads",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
      "state" : {
        "revision" : "7778cc1ab037c10dbbe026959e51e616bd961be9",
        "version" : "11.13.0"
      }
    },
    {
      "identity" : "swift-package-manager-google-user-messaging-platform",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git",
      "state" : {
        "revision" : "708a282840c2171ee63bd93b87afa49fe507d70e",
        "version" : "2.7.0"
      }
    }
  ],
  "version" : 2
}
'''
with open(os.path.join(swiftpm_dir, "Package.resolved"), "w") as fh:
    fh.write(package_resolved)

# shared scheme
sch_dir = os.path.join(PROJ_DIR, "xcshareddata", "xcschemes")
os.makedirs(sch_dir, exist_ok=True)
scheme = '''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "1520" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "%s"
               BuildableName = "Zest.app"
               BlueprintName = "Zest"
               ReferencedContainer = "container:Zest.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "%s"
            BuildableName = "Zest.app"
            BlueprintName = "Zest"
            ReferencedContainer = "container:Zest.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "%s"
            BuildableName = "Zest.app"
            BlueprintName = "Zest"
            ReferencedContainer = "container:Zest.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
''' % (target, target, target)
with open(os.path.join(sch_dir, "Zest.xcscheme"), "w") as fh:
    fh.write(scheme)

print("Generated %d source refs, %d resource refs" % (len(src), len(res)))
print("project.pbxproj bytes:", os.path.getsize(os.path.join(PROJ_DIR, "project.pbxproj")))
print("OK")
