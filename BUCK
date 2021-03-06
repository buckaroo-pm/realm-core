load('//:subdir_glob.bzl', 'subdir_glob')
load('//:utils.bzl', 'extract')
load('//:buckaroo_macros.bzl', 'buckaroo_deps_from_package')

windows_srcs = glob([
  'src/win32/**/*.cpp'
])

platform_srcs = windows_srcs

pegtl = \
  buckaroo_deps_from_package('github.com/buckaroo-pm/taocpp-pegtl')

host_core_foundation = \
  buckaroo_deps_from_package('github.com/buckaroo-pm/host-core-foundation')

genrule(
  name = 'cmake',
  out = 'out',
  cacheable = False,
  srcs = glob([
    '*.list',
    '*.txt',
    'src/**/*.txt',
    'src/**/*.in',
    'src/**/*.hpp',
    'src/**/*.h',
    'src/**/*.cpp',
    'src/**/*.c',
    'tools/**/*.in',
    'tools/**/*.cmake',
    'tools/**/*.cpp',
    'tools/**/*.txt',
    'tools/**/*.a',
    'tools/**/*.sh',
  ]),
  cmd = ' && '.join([
    'cp -r $SRCDIR/. $TMP',
    'cd $TMP',
    'cmake -DREALM_SKIP_SHARED_LIB=ON -DREALM_BUILD_LIB_ONLY=ON -DREALM_NO_TESTS=ON $SRCDIR',
    'mkdir -p $OUT',
    'cp $TMP/src/realm/version.hpp $OUT/version.hpp',
    'cp $TMP/src/realm/util/config.h $OUT/config.h',
  ]),
)

cxx_library(
  name = 'realm-core',
  header_namespace = '',
  exported_headers = dict(
    subdir_glob([
      ('src', 'realm/**/*.hpp'),
      ('src', 'realm/**/*.h'),
      ('src', '*.hpp'),
    ]).items() + [
      ('realm/version.hpp', extract(':cmake', 'version.hpp')),
      ('realm/util/config.h', extract(':cmake', 'config.h')),
    ]
  ),
  srcs = glob([
    'src/realm/**/*.cpp',
  ], exclude = glob([
    'src/realm/exec/**/*.cpp',
    'src/realm/tools/**/*.cpp',
  ]) + platform_srcs),
  platform_srcs = [
    ('windows.*', windows_srcs),
  ],
  deps = pegtl,
  platform_deps = [
    ('iphone.*', host_core_foundation),
    ('macos.*', host_core_foundation),
  ],
  visibility = [
    'PUBLIC',
  ],
)
