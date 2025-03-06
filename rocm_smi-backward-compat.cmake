# Copyright (c) 2022 Advanced Micro Devices, Inc. All Rights Reserved.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

cmake_minimum_required(VERSION 3.16.8)

set(RSMI_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR})
set(RSMI_WRAPPER_DIR ${RSMI_BUILD_DIR}/wrapper_dir)
set(RSMI_WRAPPER_INC_DIR ${RSMI_WRAPPER_DIR}/include/${ROCM_SMI})
set(OAM_TARGET_NAME "oam")
set(OAM_WRAPPER_INC_DIR ${RSMI_WRAPPER_DIR}/include/${OAM_TARGET_NAME})
set(RSMI_WRAPPER_LIB_DIR ${RSMI_WRAPPER_DIR}/${ROCM_SMI}/lib)
set(OAM_WRAPPER_LIB_DIR ${RSMI_WRAPPER_DIR}/${OAM_TARGET_NAME}/lib)
## package headers
set(PUBLIC_RSMI_HEADERS
    rocm_smi.h
    ${ROCM_SMI_TARGET}Config.h
    kfd_ioctl.h)
set(OAM_HEADERS
    oam_mapi.h
    amd_oam.h)

#Function to generate header template file
function(create_header_template)
    file(WRITE ${RSMI_WRAPPER_DIR}/header.hpp.in "/*
    Copyright (c) 2022 Advanced Micro Devices, Inc. All rights reserved.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the \"Software\"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
   */

#ifndef @include_guard@
#define @include_guard@

#ifndef ROCM_HEADER_WRAPPER_WERROR
#define ROCM_HEADER_WRAPPER_WERROR @deprecated_error@
#endif
#if ROCM_HEADER_WRAPPER_WERROR  /* ROCM_HEADER_WRAPPER_WERROR 1 */
#error \"This file is deprecated. Use file from include path /opt/rocm-ver/include/ and prefix with @prefix_name@\"
#else  /* ROCM_HEADER_WRAPPER_WERROR 0 */
#if defined(__GNUC__)
#warning \"This file is deprecated. Use file from include path /opt/rocm-ver/include/ and prefix with @prefix_name@\"
#else
#pragma message(\"This file is deprecated. Use file from include path /opt/rocm-ver/include/ and prefix with @prefix_name@\")
#endif
#endif  /* ROCM_HEADER_WRAPPER_WERROR */

@include_statements@

#endif")
endfunction()

#use header template file and generate wrapper header files
function(generate_wrapper_header)
  file(MAKE_DIRECTORY ${RSMI_WRAPPER_INC_DIR})
  set(prefix_name "${prefix_name}${ROCM_SMI}")
  #Generate wrapper header files from  the list
  foreach(header_file ${PUBLIC_RSMI_HEADERS})
    # set include guard
    get_filename_component(INC_GAURD_NAME ${header_file} NAME_WE)
    string(TOUPPER ${INC_GAURD_NAME} INC_GAURD_NAME)
    set(include_guard "${include_guard}COMGR_WRAPPER_INCLUDE_${INC_GAURD_NAME}_H")
    #set #include statement
    get_filename_component(file_name ${header_file} NAME)
    set(include_statements "${include_statements}#include \"../../../${CMAKE_INSTALL_INCLUDEDIR}/${ROCM_SMI}/${file_name}\"\n")
    configure_file(${RSMI_WRAPPER_DIR}/header.hpp.in ${RSMI_WRAPPER_INC_DIR}/${file_name})
    unset(include_guard)
    unset(include_statements)
  endforeach()
  unset(prefix_name)

#OAM Wrpper Header file generation
  file(MAKE_DIRECTORY ${OAM_WRAPPER_INC_DIR})
  set(prefix_name "${prefix_name}${OAM_TARGET_NAME}")
  #Generate wrapper header files from  the list
  foreach(header_file ${OAM_HEADERS})
    # set include guard
    get_filename_component(INC_GAURD_NAME ${header_file} NAME_WE)
    string(TOUPPER ${INC_GAURD_NAME} INC_GAURD_NAME)
    set(include_guard "${include_guard}COMGR_WRAPPER_INCLUDE_${INC_GAURD_NAME}_H")
    #set #include statement
    get_filename_component(file_name ${header_file} NAME)
    set(include_statements "${include_statements}#include \"../../../${CMAKE_INSTALL_INCLUDEDIR}/${OAM_TARGET_NAME}/${file_name}\"\n")
    configure_file(${RSMI_WRAPPER_DIR}/header.hpp.in ${OAM_WRAPPER_INC_DIR}/${file_name})
    unset(include_guard)
    unset(include_statements)
  endforeach()
  unset(prefix_name)

endfunction()

#function to create symlink to libraries
function(create_library_symlink)

  file(MAKE_DIRECTORY ${RSMI_WRAPPER_LIB_DIR})
  if(BUILD_SHARED_LIBS)

    #get rsmi lib versions
    set(SO_VERSION_GIT_TAG_PREFIX "rsmi_so_ver")
    get_version_from_tag("1.0.0.0" ${SO_VERSION_GIT_TAG_PREFIX} GIT)
    if(${ROCM_PATCH_VERSION})
      set(VERSION_PATCH ${ROCM_PATCH_VERSION})
      set(SO_VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")
    else()
      set(SO_VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}")
    endif()

    #link RSMI library files
    set(LIB_RSMI "${ROCM_SMI_LIB_NAME}.so")
    set(library_files "${LIB_RSMI}"  "${LIB_RSMI}.${VERSION_MAJOR}" "${LIB_RSMI}.${SO_VERSION_STRING}")
  else()
    set(LIB_RSMI "${ROCM_SMI_LIB_NAME}.a")
    set(library_files "${LIB_RSMI}")
  endif()

  foreach(file_name ${library_files})
     add_custom_target(link_${file_name} ALL
                  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                  COMMAND ${CMAKE_COMMAND} -E create_symlink
                  ../../${CMAKE_INSTALL_LIBDIR}/${file_name} ${RSMI_WRAPPER_LIB_DIR}/${file_name})
  endforeach()

  file(MAKE_DIRECTORY ${OAM_WRAPPER_LIB_DIR})
  if(BUILD_SHARED_LIBS)

    #get OAM lib versions
    set(SO_VERSION_GIT_TAG_PREFIX "oam_so_ver")
    get_version_from_tag("1.0.0.0" ${SO_VERSION_GIT_TAG_PREFIX} GIT)
    if(${ROCM_PATCH_VERSION})
      set(VERSION_PATCH ${ROCM_PATCH_VERSION})
      set(SO_VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")
    else()
      set(SO_VERSION_STRING "${VERSION_MAJOR}.${VERSION_MINOR}")
    endif()

    #link OAM library files
    set(LIB_OAM "lib${OAM_TARGET_NAME}.so")
    set(library_files "${LIB_OAM}"  "${LIB_OAM}.${VERSION_MAJOR}" "${LIB_OAM}.${SO_VERSION_STRING}")
  else()
    set(LIB_OAM "lib${OAM_TARGET_NAME}.a")
    set(library_files "${LIB_OAM}")
  endif()

  foreach(file_name ${library_files})
     add_custom_target(link_${file_name} ALL
                  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                  COMMAND ${CMAKE_COMMAND} -E create_symlink
                  ../../${CMAKE_INSTALL_LIBDIR}/${file_name} ${OAM_WRAPPER_LIB_DIR}/${file_name})
  endforeach()

endfunction()

#Creater a template for header file
create_header_template()
#Use template header file and generater wrapper header files
generate_wrapper_header()
install(DIRECTORY ${RSMI_WRAPPER_INC_DIR}
        DESTINATION ${ROCM_SMI}/include
        COMPONENT dev)
install(DIRECTORY ${OAM_WRAPPER_INC_DIR}
        DESTINATION ${OAM_TARGET_NAME}/include
        COMPONENT dev)
# Create symlink to library files
create_library_symlink()
install(DIRECTORY ${RSMI_WRAPPER_LIB_DIR}
        DESTINATION ${ROCM_SMI}
        COMPONENT dev)
install(DIRECTORY ${OAM_WRAPPER_LIB_DIR}
        DESTINATION ${OAM_TARGET_NAME}
        COMPONENT dev )
