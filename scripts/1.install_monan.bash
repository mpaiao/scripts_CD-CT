#!/bin/bash 

#-----------------------------------------------------------------------------#
# !SCRIPT: install_monan
#
# !DESCRIPTION:
#     Script to install the MONAN model and convert_MPAS.
#     
#     Performs the following tasks:
# 
#        o Clone the Monan model github repository in a local directory
#        o Make the script make-all.sh that compiles the Atmosphere Model and the Init Atmosphere Model
#        o As alternative for advanced users, this script creates a simple compile script that just compile the Atmosphere Model
#        o Clone the Convert_mpas tool from the monanadmin repository for convert the output model files in lat-lon grid.
#        o Compile the convert_mpas
#
#-----------------------------------------------------------------------------#


#--- Function that shows usage.
function show_usage() {
   echo " Usage: "
   echo ""
   echo " ${0} -gm GIT_MONAN -bm TAG_MONAN \\"
   echo "    -gc GIT_CONVERT_MPAS -bc TAG_CONVERT_MPAS"
   echo ""
   echo " List of optional flags: "
   echo ""
   echo " -gm GIT_MONAN   -- GitHub handle for MONAN. For example:"
   echo "                    https://github.com/monanadmin/MONAN-Model.git"
   echo " -bm TAG_MONAN   -- branch or tag name of the MONAN repository. For example:"
   echo "                    \"develop\"."
   echo " -gm GIT_CONVERT -- GitHub handle for MONAN. For example:"
   echo "                    https://github.com/monanadmin/MONAN-Model.git"
   echo " -bm TAG_CONVERT -- branch or tag name of the MONAN repository. For example:"
   echo "                    \"develop\"."
   echo ""
}
#---~---



#Functions -------------------------------------------------------------------#
function checkout_system() {
  local source_dir=$1
  local github_link=$2
  local tag_or_branch_name=$3
  if [ -d "${source_dir}" ]; then
      echo -e  "${GREEN}==>${NC} Source dir already exists, updating it ...\n"
  else
      echo -e  "${GREEN}==>${NC} Cloning your fork repository...\n"
      git clone ${github_link} ${source_dir}
      if [ ! -d "${source_dir}" ]; then
          echo -e "${RED}==>${NC} An error occurred while cloning your fork. Possible causes:  wrong URL, user or password.\n"
          exit -1
      fi
  fi

  cd ${source_dir}
  if git checkout "${tag_or_branch_name}" 2>/dev/null; then
      git pull
      echo -e "${GREEN}==>${NC} Successfully checked out and updated: ${BLUE}${tag_or_branch_name}"
  else
      echo -e "${RED}==>${NC} Failed to check out branch: ${BLUE}${tag_or_branch_name}"
      echo -e "${RED}==>${NC} Please check if you have this branch. Exiting ..."
      exit -1
  fi
  git log -1 --name-only
}
#-----------------------------------------------------------------------------#


#--- Parse arguments.
github_link_MONAN="https://github.com/monanadmin/MONAN-Model.git"
tag_or_branch_name_MONAN=1.3.0-rc
github_link_CONVERT_MPAS="https://github.com/monanadmin/convert_mpas.git"
tag_or_branch_name_CONVERT_MPAS=1.0.1
while [[ ${#} > 0 ]]
do
   key="${1}"
   case ${key} in
   -bc)
      tag_or_branch_name_CONVERT_MPAS="${2}"
      shift 2 # past flag and argument
      ;;
   -bm)
      tag_or_branch_name_MONAN="${2}"
      shift 2 # past flag and argument
      ;;
   -gc)
      github_link_CONVERT_MPAS="${2}"
      shift 2 # past flag and argument
      ;;
   -gm)
      github_link_MONAN="${2}"
      shift 2 # past flag and argument
      ;;
   *)
      echo "Unknown key-value argument pair."
      show_usage
      exit 2
      ;;
   esac
done
#---~---


#--- Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Load MONAN settings.\n"
. setenv.bash
#---~---

# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT;  mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;    mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;            mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;              mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;            mkdir -p ${DATAOUT}
DATAOUTCRON=${DATAOUT}/cron;            mkdir -p ${DATAOUTCRON}
SOURCES=${DIRHOMES}/sources;            mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;                mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:-----------------------------------------------------
tag_or_branch_name_MONAN=${tag_or_branch_name_MONAN:="1.0.0"}
tag_or_branch_name_CONVERT_MPAS=${tag_or_branch_name_CONVERT_MPAS:="1.0.0"}
echo "MONAN branch name in use: ${tag_or_branch_name_MONAN}"
echo "convert_mpas branch name in use: ${tag_or_branch_name_CONVERT_MPAS}"
#----------------------------------------------------------------------


# Local variables:-----------------------------------------------------
MONANDIR=${SOURCES}/MONAN-Model_${tag_or_branch_name_MONAN}
CONVERT_MPAS_DIR=${SOURCES}/convert_mpas_${tag_or_branch_name_CONVERT_MPAS}
$(sed -i "s;MONANDIR=.*$;MONANDIR=$MONANDIR;" setenv.bash)
#----------------------------------------------------------------------

checkout_system ${MONANDIR} ${github_link_MONAN} ${tag_or_branch_name_MONAN}
checkout_system ${CONVERT_MPAS_DIR} ${github_link_CONVERT_MPAS} ${tag_or_branch_name_CONVERT_MPAS}

rm -rf $MONANDIR/default_inputs/ 
rm -f  $MONANDIR/stream_list.* $MONANDIR/streams.* $MONANDIR/namelist.* 
rm -f  $MONANDIR/make*.output.atmosphere $MONANDIR/make*.output.init_atmosphere $MONANDIR/make.sh $MONANDIR/make-all.sh


#CR: TODO: maybe later move this make script to main scripts directory.
echo ""
echo -e  "${GREEN}==>${NC} Making compile script...\n"

cd $MONANDIR

cat << EOF > make-all.sh
#!/bin/bash
#Usage: make target CORE=[core] [options]
#Example targets:
#    ifort
#    gfortran
#    xlf
#    pgi
#Availabe Cores:
#    atmosphere
#    init_atmosphere
#    landice
#    ocean
#    seaice
#    sw
#    test
#Available Options:
#    DEBUG=true    - builds debug version. Default is optimized version.
#    USE_PAPI=true - builds version using PAPI for timers. Default is off.
#    TAU=true      - builds version using TAU hooks for profiling. Default is off.
#    AUTOCLEAN=true    - forces a clean of infrastructure prior to build new core.
#    GEN_F90=true  - Generates intermediate .f90 files through CPP, and builds with them.
#    TIMER_LIB=opt - Selects the timer library interface to be used for profiling the model. Options are:
#                    TIMER_LIB=native - Uses native built-in timers in MPAS
#                    TIMER_LIB=gptl - Uses gptl for the timer interface instead of the native interface
#                    TIMER_LIB=tau - Uses TAU for the timer interface instead of the native interface
#    OPENMP=true   - builds and links with OpenMP flags. Default is to not use OpenMP.
#    OPENACC=true  - builds and links with OpenACC flags. Default is to not use OpenACC.
#    USE_PIO2=true - links with the PIO 2 library. Default is to use the PIO 1.x library.
#    PRECISION=single - builds with default single-precision real kind. Default is to use double-precision.
#    SHAREDLIB=true - generate position-independent code suitable for use in a shared library. Default is false.


. ${SCRIPTS}/setenv.bash
rm -fr ${MONANDIR}/stream* ${MONANDIR}/namelist.* ${MONANDIR}/make_*output.atmosphere ${MONANDIR}/default_inputs
DATE_TIME_NOW=\$(date +"%Y%m%d%H%M%S")

export NETCDF=${NETCDFDIR}
export PNETCDF=${PNETCDFDIR}
# PIO is not necessary for version 8.* If PIO is empty, MPAS Will use SMIOL
export PIO=

MAKE_OUT_FILE="make_\${DATE_TIME_NOW}_.output.atmosphere"
make clean CORE=atmosphere
make -j 8 gfortran CORE=atmosphere OPENMP=true USE_PIO2=false PRECISION=single 2>&1 | tee \${MAKE_OUT_FILE}

#CR: TODO: put verify here if executable was created ok
mv ${MONANDIR}/atmosphere_model ${EXECS}
mv ${MONANDIR}/build_tables ${EXECS}
cp ${MONANDIR}/VERSION.txt ${EXECS}
cp ${MONANDIR}/GF_ConvPar_nml ${SCRIPTS}
make clean CORE=atmosphere

MAKE_OUT_FILE="make_\${DATE_TIME_NOW}_.output.init_atmosphere"
make clean CORE=init_atmosphere
make -j 8 gfortran CORE=init_atmosphere OPENMP=true USE_PIO2=false PRECISION=single 2>&1 | tee \${MAKE_OUT_FILE}

mv ${MONANDIR}/init_atmosphere_model ${EXECS}
make clean CORE=init_atmosphere


if [ -s "${EXECS}/init_atmosphere_model" ] && [ -e "${EXECS}/atmosphere_model" ]; then
    echo ""
    echo -e "${GREEN}==>${NC} Files init_atmosphere_model and atmosphere_model generated Successfully in ${EXECS} !"
    echo
else
    echo -e "${RED}==>${NC} !!! An error occurred during build. Check output"
    exit -1
fi

EOF
chmod a+x make-all.sh


cat << EOF > make.sh
#!/bin/bash
#Usage: make target CORE=[core] [options]
#Example targets:
#    ifort
#    gfortran
#    xlf
#    pgi
#Availabe Cores:
#    atmosphere
#    init_atmosphere
#    landice
#    ocean
#    seaice
#    sw
#    test
#Available Options:
#    DEBUG=true    - builds debug version. Default is optimized version.
#    USE_PAPI=true - builds version using PAPI for timers. Default is off.
#    TAU=true      - builds version using TAU hooks for profiling. Default is off.
#    AUTOCLEAN=true    - forces a clean of infrastructure prior to build new core.
#    GEN_F90=true  - Generates intermediate .f90 files through CPP, and builds with them.
#    TIMER_LIB=opt - Selects the timer library interface to be used for profiling the model. Options are:
#                    TIMER_LIB=native - Uses native built-in timers in MPAS
#                    TIMER_LIB=gptl - Uses gptl for the timer interface instead of the native interface
#                    TIMER_LIB=tau - Uses TAU for the timer interface instead of the native interface
#    OPENMP=true   - builds and links with OpenMP flags. Default is to not use OpenMP.
#    OPENACC=true  - builds and links with OpenACC flags. Default is to not use OpenACC.
#    USE_PIO2=true - links with the PIO 2 library. Default is to use the PIO 1.x library.
#    PRECISION=single - builds with default single-precision real kind. Default is to use double-precision.
#    SHAREDLIB=true - generate position-independent code suitable for use in a shared library. Default is false.

. ${SCRIPTS}/setenv.bash
rm -fr ${MONANDIR}/stream* ${MONANDIR}/namelist.* ${MONANDIR}/make_*output.atmosphere ${MONANDIR}/default_inputs
DATE_TIME_NOW=\$(date +"%Y%m%d%H%M%S")


export NETCDF=${NETCDFDIR}
export PNETCDF=${PNETCDFDIR}
# PIO is not necessary for version 8.* If PIO is empty, MPAS Will use SMIOL
export PIO=

MAKE_OUT_FILE="make_\${DATE_TIME_NOW}_.output.atmosphere"
make clean CORE=atmosphere
make -j 8 gfortran CORE=atmosphere OPENMP=true USE_PIO2=false PRECISION=single 2>&1 | tee \${MAKE_OUT_FILE}

#CR: TODO: put verify here if executable was created ok
mv ${MONANDIR}/atmosphere_model ${EXECS}
mv ${MONANDIR}/build_tables ${EXECS}
make clean CORE=atmosphere

if  [ -e "${EXECS}/atmosphere_model" ]; then
    echo ""
    echo -e "${GREEN}==>${NC} Files init_atmosphere_model and atmosphere_model generated Successfully in ${EXECS} !"
    echo
else
    echo -e "${RED}==>${NC} !!! An error occurred during build. Check output"
    exit -1
fi

EOF
chmod a+x make.sh


echo ""
echo -e  "${GREEN}==>${NC} Installing init_atmosphere_model and atmosphere_model...\n"
echo ""

#CR: TODO: maybe at this point we should put our registry-file et all.
#CR: make-all.sh compile all for the first time
#CR: make.sh just compile  the A-model
. ${MONANDIR}/make-all.sh


# install convert_mpas
echo ""
echo -e  "${GREEN}==>${NC} Moduling environment for convert_mpas...\n"
module purge
module load gnu9/9.4.0
module load ohpc
module load phdf5
module load netcdf
module load netcdf-fortran
module list

cd ${CONVERT_MPAS_DIR}
echo ""
echo -e  "${GREEN}==>${NC} Installing convert_mpas...\n"
make clean
make  2>&1 | tee make.convert.output

#CR: TODO: put verify here if executable was created ok
mv ${CONVERT_MPAS_DIR}/convert_mpas ${EXECS}/

if [ -s "${EXECS}/convert_mpas" ] ; then
    echo ""
    echo -e "${GREEN}==>${NC} File convert_mpas generated Sucessfully in ${CONVERT_MPAS_DIR} and copied to ${EXECS} !"
    echo
else
    echo -e "${RED}==>${NC} !!! An error occurred during convert_mpas build. Check output"
    exit -1
fi

