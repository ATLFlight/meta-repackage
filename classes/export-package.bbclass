# This class requires PREBUILT_DIR to be defined
# which is the directory to write the prebuilt packages
# and associated metadata

# This class has been designed to work with ipk packages
# but could be extended to other package types
PKG_TYPE = "ipk"

LICENSE       = "CLOSED"
LICENSE_FLAGS = "commercial"

# name of the package containing the license text
# Usually in /usr/share/...
IMPORT_LICENSE_PKGNAME = ""

python() {
    lic_pkg = d.getVar('IMPORT_LICENSE_PKGNAME', True)
    if lic_pkg:
        if d.getVar('PN', True) != lic_pkg:
            d.appendVarFlag("do_package_write_prebuilt", "depends", " %s:do_package_write_prebuilt" % lic_pkg)
}

python do_package_write_prebuilt() {
    import shutil
    import glob
    import json
    import codecs

    pn = d.getVar('PN', True)
    pv = d.getVar('PV', True)
    pr = d.getVar('PR', True)
    packages = d.getVar('PACKAGES', True) or ""
    workdir = d.getVar('WORKDIR', True)
    pkgarch = d.getVar('PACKAGE_ARCH', True)
    destdir = d.getVar('PREBUILT_DIR', True)
    curdir = os.getcwd()
    os.chdir(os.path.join(workdir, "deploy-ipks", pkgarch))

    # Do not copy dbg packages
    pkgs = []
    for p in glob.glob("*.${PKG_TYPE}"):
        if "-dbg_" not in p:
            shutil.copyfile(p, os.path.join(destdir, p))
            pkg = p.split("_")[0]
            if pkg not in packages:
                bb.warn("REMAPPED PACKAGE: "+p)
            pkgs.append(p)
    os.chdir(curdir)
    info = {}
    info['PKGMAP'] =  pkgs
    info['HOMEPAGE'] = d.getVar('HOMEPAGE', True)
    info['SECTION'] = d.getVar('SECTION', True)
    info['DESCRIPTION'] = d.getVar('DESCRIPTION', True)
    info['MAINTAINER'] = d.getVar('MAINTAINER', True)
    info['PROVIDES'] = ' '.join(d.getVar('PROVIDES', True).split())

    for p in packages.split():
        #bb.warn("Checking RDEPENDS_"+p)
        rdepends = d.getVar('RDEPENDS_'+p, True)
        if rdepends:
            info['RDEPENDS_'+p] = ' '.join(rdepends.split())
        provides = d.getVar('RPROVIDES_'+p, True)
        if provides:
            info['RPROVIDES_'+p] = ' '.join(provides.split())
        if p in info['PROVIDES'] and not p.endswith("-dbg"):
            files = d.getVar('FILES_'+p, True)
            if files:
                info['FILES_'+p] = ' '.join(files.split())

    pkgidxfile = os.path.join(destdir, "%s_%s-%s_%s.pkgs" % (pn, pv, pr, pkgarch))
    with codecs.open(pkgidxfile, mode='w', encoding='utf-8') as f:
        f.write(json.dumps(info, indent=4))
}

do_package_write_prebuilt[nostamp] = "1"

addtask do_package_write_prebuilt before do_package_write after do_package_write_ipk
do_build[recrdeptask] += "do_package_write_prebuilt"

python clean_prebuilt() {
    pn = d.getVar('PN', True)
    destdir = d.getVar('PREBUILT_DIR', True)
    pkgs = os.path.join(destdir, pn+".pkgs")
    if os.path.exists(pkgs):
        pkglist = open(pkgs, "r").read().split()
        for p in pkglist:
            os.remove(os.path.join(destdir, p))
        os.remove(pkgs)
}

CLEANFUNCS += "clean_prebuilt"
