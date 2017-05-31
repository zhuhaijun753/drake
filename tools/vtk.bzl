# -*- mode: python -*-
# vi: set ft=python :

"""
Makes selected VTK headers and precompiled shared libraries available to be
used as a C/C++ dependency. On Ubuntu Trusty and Xenial, a VTK archive is
downloaded and unpacked. On macOS and OS X, VTK must be installed using
Homebrew.

Example:
    WORKSPACE:
        load("//tools:vtk.bzl", "vtk_repository")
        vtk_repository(name = "foo")

    BUILD:
        cc_library(
            name = "foobar",
            deps = ["@foo//:vtkCommonCore"],
            srcs = ["bar.cc"],
        )

Argument:
    name: A unique name for this rule.
"""

VTK_MAJOR_MINOR_VERSION = "7.1"

def _vtk_cc_library(os_name, name, hdrs=None, visibility=None, deps=None,
                    header_only=False):
    hdr_paths = []

    if hdrs:
        includes = ["include/vtk-{}".format(VTK_MAJOR_MINOR_VERSION)]

        if not visibility:
            visibility = ["//visibility:public"]

        for hdr in hdrs:
            hdr_paths += ["{}/{}".format(includes[0], hdr)]
    else:
        includes = []

        if not visibility:
            visibility = ["//visibility:private"]

    if not deps:
        deps = []

    linkopts = []
    srcs = []

    if os_name == "mac os x":
        srcs = ["empty.cc"]

        if not header_only:
            linkopts = [
                "-L/usr/local/opt/vtk@8.0/lib",
                "-l{}-{}".format(name, VTK_MAJOR_MINOR_VERSION),
            ]
    else:
        if not header_only:
            srcs = ["lib/lib{}-{}.so.1".format(name, VTK_MAJOR_MINOR_VERSION)]

    content = """
cc_library(
    name = "{}",
    srcs = {},
    hdrs = {},
    includes = {},
    linkopts = {},
    visibility = {},
    deps = {},
)
    """.format(name, srcs, hdr_paths, includes, linkopts, visibility, deps)

    return content

def _impl(repository_ctx):
    if repository_ctx.os.name == "mac os x":
        # TODO(jamiesnape): Use VTK_MAJOR_MINOR_VERSION instead of hard-coding.
        repository_ctx.symlink("/usr/local/opt/vtk@8.0/include", "include")
        repository_ctx.file("empty.cc", executable=False)

    elif repository_ctx.os.name == "linux":
        lsb_release = repository_ctx.which("lsb_release")
        result = repository_ctx.execute([lsb_release, "--codename"])

        if result.return_code != 0:
            fail("Could NOT determine Linux distribution codename",
                 attr=result.stderr)

        codename = result.stdout.split(':')[1].strip()

        if codename == "trusty":
            archive = "vtk-v7.1.1-1584-g28deb56-qt-4.8.6-trusty-x86_64.tar.gz"
            sha256 = "709fb9a5197ee5a87bc92760c2fe960b89326acd11a0ce6adf9d7d023563f5d4"
        elif codename == "xenial":
            archive = "vtk-v7.1.1-1584-g28deb56-qt-5.5.1-xenial-x86_64.tar.gz"
            sha256 = "d21cae88b2276fd59c94f0e41244fc8f7e31ff796518f731e4fffc25f8e01cbc"
        else:
            fail("Linux distribution is NOT supported", attr=codename)

        url = "https://d2mbb5ninhlpdu.cloudfront.net/vtk/{}".format(archive)
        root_path = repository_ctx.path("")

        repository_ctx.download_and_extract(url, root_path, sha256=sha256)

    else:
        fail("Operating system is NOT supported", attr=repository_ctx.os.name)

    # Note that we only create library targets for enough of VTK to support
    # those used directly or indirectly by Drake.

    # TODO(jamiesnape): Create a script to help generate the targets.

    file_content = _vtk_cc_library(repository_ctx.os.name, "vtkCommonColor",
        deps = [
            ":vtkCommonCore",
            ":vtkCommonDataModel",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name,
        "vtkCommonComputationalGeometry",
        deps = [
            ":vtkCommonCore",
            ":vtkCommonDataModel",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkCommonCore",
        hdrs = [
            "vtkABI.h",
            "vtkAbstractArray.h",
            "vtkAOSDataArrayTemplate.h",
            "vtkAOSDataArrayTemplate.txx",
            "vtkArrayIterator.h",
            "vtkArrayIteratorTemplate.h",
            "vtkArrayIteratorTemplate.txx",
            "vtkAtomic.h",
            "vtkAtomicTypeConcepts.h",
            "vtkAtomicTypes.h",
            "vtkAutoInit.h",
            "vtkBuffer.h",
            "vtkCollection.h",
            "vtkCommonCoreModule.h",
            "vtkConfigure.h",
            "vtkDataArray.h",
            "vtkDebugLeaksManager.h",
            "vtkGenericDataArray.h",
            "vtkGenericDataArray.txx",
            "vtkGenericDataArrayLookupHelper.h",
            "vtkIdList.h",
            "vtkIdTypeArray.h",
            "vtkIndent.h",
            "vtkIntArray.h",
            "vtkIOStream.h",
            "vtkMath.h",
            "vtkMathConfigure.h",
            "vtkNew.h",
            "vtkObject.h",
            "vtkObjectBase.h",
            "vtkObjectFactory.h",
            "vtkOStreamWrapper.h",
            "vtkOStrStreamWrapper.h",
            "vtkPoints.h",
            "vtkSetGet.h",
            "vtkSmartPointer.h",
            "vtkSmartPointerBase.h",
            "vtkStdString.h",
            "vtkSystemIncludes.h",
            "vtkTimeStamp.h",
            "vtkType.h",
            "vtkTypeTraits.h",
            "vtkUnicodeString.h",
            "vtkUnsignedCharArray.h",
            "vtkVariant.h",
            "vtkVariantCast.h",
            "vtkVariantInlineOperators.h",
            "vtkVersion.h",
            "vtkVersionMacros.h",
            "vtkWeakPointerBase.h",
            "vtkWin32Header.h",
            "vtkWindow.h",
            "vtkWrappingHints.h",
        ],
        deps = [
            ":vtkkwiml",
            ":vtksys",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name,
        "vtkCommonDataModel",
        hdrs = [
            "vtkAbstractCellLinks.h",
            "vtkCell.h",
            "vtkCellArray.h",
            "vtkCellData.h",
            "vtkCellLinks.h",
            "vtkCellType.h",
            "vtkCellTypes.h",
            "vtkCommonDataModelModule.h",
            "vtkDataObject.h",
            "vtkDataSet.h",
            "vtkDataSetAttributes.h",
            "vtkFieldData.h",
            "vtkImageData.h",
            "vtkPointSet.h",
            "vtkPolyData.h",
            "vtkRect.h",
            "vtkStructuredData.h",
            "vtkVector.h",
        ],
        deps = [
            ":vtkCommonCore",
            ":vtkCommonMath",
            ":vtkCommonMisc",
            ":vtkCommonSystem",
            ":vtkCommonTransforms",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name,
        "vtkCommonExecutionModel",
        hdrs = [
            "vtkAlgorithm.h",
            "vtkCommonExecutionModelModule.h",
            "vtkImageAlgorithm.h",
            "vtkPolyDataAlgorithm.h",
        ],
        deps = [
            ":vtkCommonCore",
            ":vtkCommonDataModel",
            ":vtkCommonMisc",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkCommonMath",
        hdrs = [
            "vtkCommonMathModule.h",
            "vtkMatrix4x4.h",
            "vtkTuple.h",
        ],
        deps = [":vtkCommonCore"],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkCommonMisc",
        deps = [
            ":vtkCommonCore",
            ":vtkCommonMath",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkCommonSystem",
        deps = [":vtkCommonCore"],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name,
        "vtkCommonTransforms",
        hdrs = [
            "vtkAbstractTransform.h",
            "vtkCommonTransformsModule.h",
            "vtkHomogeneousTransform.h",
            "vtkLinearTransform.h",
            "vtkTransform.h",
        ],
        deps = [
            ":vtkCommonCore",
            ":vtkCommonMath",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkDICOMParser",
        deps = [":vtksys"],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkFiltersCore",
        hdrs = ["vtkFiltersCoreModule.h"],
        visibility = ["//visibility:private"],
        deps = [
            ":vtkCommonCore",
            ":vtkCommonDataModel",
            ":vtkCommonExecutionModel",
            ":vtkCommonMisc",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name,
        "vtkFiltersGeometry",
        deps = [
            ":vtkCommonCore",
            ":vtkCommonDataModel",
            ":vtkCommonExecutionModel",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkFiltersGeneral",
        hdrs = [
            "vtkFiltersGeneralModule.h",
            "vtkTransformPolyDataFilter.h",
        ],
        deps = [
            ":vtkCommonComputationalGeometry",
            ":vtkCommonCore",
            ":vtkCommonDataModel",
            ":vtkCommonExecutionModel",
            ":vtkCommonMisc",
            ":vtkFiltersCore",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkFiltersSources",
        hdrs = [
            "vtkCubeSource.h",
            "vtkCylinderSource.h",
            "vtkFiltersSourcesModule.h",
            "vtkPlaneSource.h",
            "vtkSphereSource.h",
        ],
        deps = [
            ":vtkCommonDataModel",
            ":vtkCommonExecutionModel",
            ":vtkFiltersCore",
            ":vtkFiltersGeneral",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkIOCore",
        hdrs = [
            "vtkAbstractPolyDataReader.h",
            "vtkIOCoreModule.h",
        ],
        deps = [
            ":vtkCommonCore",
            ":vtkCommonExecutionModel",
            ":vtklz4",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkIOGeometry",
        hdrs = [
            "vtkIOGeometryModule.h",
            "vtkOBJReader.h",
        ],
        deps = [
            ":vtkCommonDataModel",
            ":vtkCommonExecutionModel",
            ":vtkIOCore",
            ":vtkIOLegacy",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkIOImage",
        hdrs = [
            "vtkImageReader2.h",
            "vtkIOImageModule.h",
            "vtkPNGReader.h",
        ],
        deps = [
            ":vtkCommonCore",
            ":vtkCommonExecutionModel",
            ":vtkDICOMParser",
            ":vtkmetaio",
            "@libpng//:lib",
            "@zlib//:lib",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkIOImport",
        hdrs = [
            "vtkImporter.h",
            "vtkIOImportModule.h",
            "vtkOBJImporter.h",
        ],
        deps = [
            ":vtkCommonCore",
            ":vtkCommonExecutionModel",
            ":vtkCommonMisc",
            ":vtkRenderingCore",
            ":vtksys",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkIOLegacy",
        deps = [
            ":vtkCommonCore",
            ":vtkCommonDataModel",
            ":vtkCommonExecutionModel",
            ":vtkIOCore",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkRenderingCore",
        hdrs = [
            "vtkAbstractMapper.h",
            "vtkAbstractMapper3D.h",
            "vtkActor.h",
            "vtkActorCollection.h",
            "vtkCamera.h",
            "vtkMapper.h",
            "vtkPolyDataMapper.h",
            "vtkProp.h",
            "vtkProp3D.h",
            "vtkPropCollection.h",
            "vtkProperty.h",
            "vtkRenderer.h",
            "vtkRenderingCoreModule.h",
            "vtkRenderWindow.h",
            "vtkTexture.h",
            "vtkViewport.h",
            "vtkVolume.h",
            "vtkVolumeCollection.h",
            "vtkWindowToImageFilter.h",
        ],
        deps = [
            ":vtkCommonColor",
            ":vtkCommonCore",
            ":vtkCommonDataModel",
            ":vtkCommonExecutionModel",
            ":vtkCommonMath",
            ":vtkFiltersCore",
            ":vtkFiltersGeometry",
        ],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name,
        "vtkRenderingOpenGL2",
        visibility = ["//visibility:public"],
        deps = [
            ":vtkCommonCore",
            ":vtkCommonDataModel",
            ":vtkRenderingCore",
            ":vtkglew",
        ],
    )

    if repository_ctx.os.name == "mac os x":
        file_content += """
cc_library(
    name = "vtkglew",
    srcs = ["empty.cc"],
    linkopts = [
        "-L/usr/local/opt/glew/lib",
        "-lGLEW",
    ],
    visibility = ["//visibility:private"],
)
        """
    else:
        file_content += _vtk_cc_library(repository_ctx.os.name, "vtkglew")

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkkwiml",
        hdrs = [
            "vtk_kwiml.h",
            "vtkkwiml/abi.h",
            "vtkkwiml/int.h",
        ],
        visibility = ["//visibility:private"],
        header_only = True,
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtklz4")

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtkmetaio",
        deps = ["@zlib//:lib"],
    )

    file_content += _vtk_cc_library(repository_ctx.os.name, "vtksys")

    # Glob all files for the data dependency of drake-visualizer.
    file_content += """
filegroup(
    name = "vtk",
    srcs = glob(["**/*"]),
    visibility = ["//visibility:public"],
)
"""

    repository_ctx.file("BUILD", content=file_content, executable=False)

vtk_repository = repository_rule(
    local = True,
    implementation = _impl,
)