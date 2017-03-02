# meta-repackage

This layer provides classes that work together to export proprietary packages
from a OE/Yocto build and import them into a compatible OE/Yocto build.

This is useful when you have to create proprietary bnary packages and then
provide the packages to a community build that relies on the proprietary 
binary packages.

The intention is you can have a full build with either the meta-myorg or the
meta-myorg-community layer.

### local.conf

The local.conf on both the build exporting the packages and the build importing
the packages needs to contain PREBUILT_DIR and whitelist "commercial" licenses.

Here is an example:
```
PREBUILT_VERSION = "1.0.0"
PREBUILT_DIR = "${COREBASE}/../prebuilt_${MACHINE}/${PREBUILT_VERSION}/"
LICENSE_FLAGS_WHITELIST += "commercial"
```

## Proprietary packages

### Custom Info

You can create a wrapper class to add your specific organizational info.

### meta-myorg/classes/myorg-export-package.bbclass:
```
inherit export-package.bbclass

LICENSE          = "Myorg-Redistributable"
LIC_FILES_CHKSUM = "file://${PREBUILT_DIR}/LICENSE;md5=dddddddddddddddddddddddddddddddd"
LICENSE_FLAGS = "commercial"
NO_GENERIC_LICENSE[Myorg-Redistributable] = "LICENSE"

HOMEPAGE = "http://somewebsite.com"

IMPORT_LICENSE_PKGNAME = "myorg-license-redistributable"
```

### Exported packages
You will need the following for each exported package:

meta-myorg/recipes-bsp/foo/foo_git.bb:
```
inherit myorg-export-package.bbclass

DESCRIPTION = "Some package foo"
...
```

### Packaging the license

An optional package can be specified in IMPORT_LICENSE_PKGNAME
to put a copy of the license on the filesystem and have all
exported packages depend on this package.

meta-myorg/recipes-extended/myorg-license-redistributable.bb:
```
inherit allarch
inherit import-package
```

This will put a copy of the license in /usr/share/../LICENSE.${LICENSE}
as part of the myorg-license-redistributable package and the other packages
will have a dependency on this package.  

## Community build

### Custom Info

You can create a wrapper class to add your specific organizational info.

meta-myorg-community/classes/myorg-import-package.bbclass:
```
inherit import-package.bbclass
LICENSE          = "Myorg-Redistributable"
LIC_FILES_CHKSUM = "file://${PREBUILT_DIR}/LICENSE;md5=dddddddddddddddddddddddddddddddd"
LICENSE_FLAGS = "commercial"
NO_GENERIC_LICENSE[Myorg-Redistributable] = "LICENSE"
```

### Imported packages
You will need the following minimum for each imported package:

meta-myorg-community/recipes-bsp/foo/foo.bb:
```
inherit myorg-import-package
...
```
