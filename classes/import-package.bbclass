# This class requires PREBUILT_DIR to be defined
# which is the directory containing the prebuilt packages
# that will be imported into this build
#
# This class has been designed to work with ipk packages
# but could be extended to other package types
PKG_TYPE = "ipk"

# Define the license info for the imported packages
LICENSE       = "Proprietary-Redistributable"
LICENSE_FLAGS = "commercial"
NO_GENERIC_LICENSE[Proprietary-Redistributable] = "LICENSE"

# Must provide LIC_FILES_CHKSUM
# LIC_FILES_CHKSUM = "file://${PREBUILT_DIR}/LICENSE;md5=???"

# name of the package containing the license text
# Usually in /usr/share/...
IMPORT_LICENSE_PKGNAME = ""

# Default package version
PV = "1.0"
PR = "r0"

# Skip tasks
do_configure[noexec] = "1"
do_compile[noexec] = "1"

S = "${WORKDIR}/${PN}-${PV}"

INHIBIT_PACKAGE_DEBUG_SPLIT = "1"
INHIBIT_PACKAGE_STRIP = "1"

do_install () {
    [ -d "${S}" ] || exit 1
    [ -d "${D}" ] || exit 1
    rsync -rlptD  ${S}/* ${D}
}

def load_pkgs_info(d):
    import json
    import codecs

    pn = d.getVar('PN', True)
    pv = d.getVar('PV', True)
    pr = d.getVar('PR', True)
    arch = d.getVar('PACKAGE_ARCH', True)
    pkgdir = d.getVar('PREBUILT_DIR', True)
    if not pkgdir:
        bb.fatal("PREBUILT_DIR not set")

    pkgidx = "%s_%s-%s_%s.pkgs" % (pn, pv, pr, arch)
    pkgidxfile = os.path.join(pkgdir, pkgidx)
    pkginfo = {}
    if os.path.isfile(pkgidxfile):
            with codecs.open(pkgidxfile, mode='r', encoding='utf-8') as f:
                pkginfo = json.load(f)
    else:
        bb.fatal("ERROR: Missing %s" % pkgidxfile)

    return pkginfo
    

# Set variables at global scope
python() {
    import json
    pkginfo = load_pkgs_info(d)
    #bb.warn("PKGINFO = "+json.dumps(pkginfo))

    for p in pkginfo['PKGMAP']:
        d.appendVar('SRC_URI', " file://${PREBUILT_DIR}/"+p+";subdir=${PN}-${PV}")
    srcuri = d.getVar('SRC_URI', False)
    #bb.warn("SRC_URI: "+srcuri)

    for v in [ 'SECTION', 'MAINTAINER', 'DESCRIPTION', 'PROVIDES', 'DEPENDS' ]:
        if pkginfo[v]:
            d.setVar(v, pkginfo[v])

    for k in pkginfo.keys():
        if k.startswith('RDEPENDS_'):
            d.setVar(k, pkginfo[k])
        elif k.startswith('RPROVIDES_'):
            d.setVar(k, pkginfo[k])
            #bb.warn("%s: %s" % (k, pkginfo[k]))
        elif k.startswith('FILES_'):
            d.setVar(k, pkginfo[k])
            #bb.warn("%s: %s" % (k, pkginfo[k]))
    
    lic_pkg = d.getVar('IMPORT_LICENSE_PKGNAME', True)
    if lic_pkg:
        pn = d.getVar('PN', True)
        if pn != lic_pkg:
            packages = d.getVar('PACKAGES', True) or ""
            for p in packages.split():
                d.appendVar('RDEPENDS_%s' % p, "  %s" % lic_pkg)
                d.appendVar('INSANE_SKIP_%s' % pn," already-stripped")
}

python do_unpack_append() {
    import subprocess

    pkgdir = d.getVar('PREBUILT_DIR', True)
    workdir = d.getVar('WORKDIR', True)
    controldir = os.path.join(workdir, "control_files")
    pkginfo = load_pkgs_info(d)

    for p in pkginfo['PKGMAP']:
        pkg = os.path.join(pkgdir, p)

        if d.getVar('PKG_TYPE', True) == "ipk":
            # Extract the control files for future use
            pkgcontroldir=os.path.join(controldir, p)
            if not os.path.exists(pkgcontroldir):
                os.makedirs(pkgcontroldir)
            cmd = [bb.utils.which(os.getenv('PATH'), "dpkg-deb"), "-e", pkg, pkgcontroldir]

            try:
                cmd_output2 = subprocess.check_output(cmd, stderr=subprocess.STDOUT).strip().decode("utf-8")
            except subprocess.CalledProcessError as e:
                bb.fatal("Cannot extract the package. Command '%s' "
                     "returned %d:\n%s" % (' '.join(cmd), e.returncode, e.output.decode("utf-8")))
        else:
            bb.fatal("Only ipk packages are currently supported")
}
