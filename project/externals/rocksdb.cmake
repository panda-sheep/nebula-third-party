# Copyright (c) 2019 vesoft inc. All rights reserved.
#
# This source code is licensed under Apache 2.0 License.

set(name rocksdb)
set(source_dir ${CMAKE_CURRENT_BINARY_DIR}/${name}/source)
set(MakeEnvs "env" "USE_RTTI=1")

if(ENABLE_ROCKSDB_CLOUD)
    message(STATUS "use rocksdb cloud")
    ExternalProject_Add_Git(
        ${name}
        GIT_REPOSITORY https://github.com/rockset/rocksdb-cloud.git
        GIT_TAG 14ed36afbf70df1ce73f03366003e8c00ebd5e9e  # As of 2022/9/19
        GIT_SUBMODULES ""
        ARCHIVE_FILE rocksdb-2022-9-19.tar.gz
        ARCHIVE_MD5 89854dbe4a857068381b572081ab1e19
        PREFIX ${CMAKE_CURRENT_BINARY_DIR}/${name}
        TMP_DIR ${BUILD_INFO_DIR}
        STAMP_DIR ${BUILD_INFO_DIR}
        DOWNLOAD_DIR ${DOWNLOAD_DIR}
        PATCH_COMMAND patch -p1 < ${CMAKE_SOURCE_DIR}/patches/${name}-2022-9-19.patch
        SOURCE_DIR ${source_dir}
        SOURCE_SUBDIR rocksdb
        CONFIGURE_COMMAND ""
        BUILD_COMMAND 
            "${MakeEnvs}"
             make static_lib -e -s -j${BUILDING_JOBS_NUM}
        BUILD_IN_SOURCE 1
        INSTALL_COMMAND 
            make -C lib
               -s install-pc install-static install-includes
               -j${BUILDING_JOBS_NUM}
               PREFIX=${CMAKE_INSTALL_PREFIX}
        LOG_CONFIGURE TRUE
        LOG_BUILD TRUE
        LOG_INSTALL TRUE
    )
    #message(FATAL_ERROR "use rocksdb cloud!")

else()
    message(STATUS "use rocksdb native")
    ExternalProject_Add(
        ${name}
        URL https://github.com/facebook/rocksdb/archive/refs/tags/v7.5.3.tar.gz
        URL_HASH MD5=5195c23691906f557aaa1827291196fd
        DOWNLOAD_NAME rocksdb-7.5.3.tar.gz
        PREFIX ${CMAKE_CURRENT_BINARY_DIR}/${name}
        TMP_DIR ${BUILD_INFO_DIR}
        STAMP_DIR ${BUILD_INFO_DIR}
        DOWNLOAD_DIR ${DOWNLOAD_DIR}
        SOURCE_DIR ${source_dir}
        UPDATE_COMMAND ""
        CMAKE_ARGS
        ${common_cmake_args}
        -DPORTABLE=ON
        -DWITH_SNAPPY=ON
        -DWITH_ZSTD=ON
        -DWITH_ZLIB=ON
        -DWITH_LZ4=ON
        -DWITH_BZ2=ON
        -DWITH_JEMALLOC=OFF
        -DWITH_GFLAGS=OFF
        -DWITH_TESTS=OFF
        -DWITH_BENCHMARK_TOOLS=OFF
        -DWITH_TOOLS=OFF
        -DUSE_RTTI=ON
        -DFAIL_ON_WARNINGS=OFF
        -DCMAKE_BUILD_TYPE=Release
        "-DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} -D NPERF_CONTEXT"
        BUILD_IN_SOURCE 1
        BUILD_COMMAND make -s -j${BUILDING_JOBS_NUM}
        INSTALL_COMMAND ""
        LOG_CONFIGURE TRUE
        LOG_BUILD TRUE
        LOG_INSTALL TRUE
    )
    message(FATAL_ERROR "use rocksdb native!")
   
   ExternalProject_Add_Step(${name} install-static
    DEPENDEES build
    DEPENDERS install
    ALWAYS false
    COMMAND
    make -s install -j${BUILDING_JOBS_NUM}
    COMMAND
    find ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR} -name "librocksdb.so*" -delete
    WORKING_DIRECTORY ${source_dir}
)
endif()

ExternalProject_Add_Step(${name} clean
    EXCLUDE_FROM_MAIN TRUE
    ALWAYS TRUE
    DEPENDEES configure
    COMMAND make clean -j
    COMMAND rm -f ${BUILD_INFO_DIR}/${name}-build
    WORKING_DIRECTORY ${source_dir}
)

ExternalProject_Add_StepTargets(${name} clean)

